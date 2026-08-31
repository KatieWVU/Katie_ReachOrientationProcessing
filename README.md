# Reach Orientation Processing

## Status

This repository contains early MATLAB code for the `DATASET_REACH_ORIENTATION`
study. The analysis below is a proposed replacement plan. Implementation has not
started and must not write events to the shared dataset until the dry-run output
for subject 6 / trial type 10 has been reviewed and approved.

## Scientific scope

The relevant experiment asked participants to make repeated horizontal or
vertical pointing movements while the arm/body was oriented differently with
respect to gravity. The accompanying 2025 SFN poster describes this as the
second experiment in Methods. The parabolic-flight experiment and its 0g/1g/2g
data are out of scope here.

Analyze only:

- `idSubject = [1 4 6 7 8 9]`
- enabled trials (`bTrial == 1`)
- `idTrialType = 7:14`
- the three accelerometer axes from one representative forearm sensor: FCR,
  ECU, or FCU

Do not include later subjects whose orientation measurements are stored as
quaternions.

The target trial types are:

| idTrialType | Name | Movement plane | Pace |
| ---: | --- | --- | ---: |
| 7 | `UP_HF` | horizontal | 120 bpm |
| 8 | `UP_HS` | horizontal | 80 bpm |
| 9 | `SIDE_HF` | horizontal | 120 bpm |
| 10 | `SIDE_HS` | horizontal | 80 bpm |
| 11 | `SIDE_VF` | vertical | 120 bpm |
| 12 | `SIDE_VS` | vertical | 80 bpm |
| 13 | `UP_VF` | vertical | 120 bpm |
| 14 | `UP_VS` | vertical | 80 bpm |

Not every requested subject has every trial type. Subject 1 has no enabled
types 12-14, subject 4/type 7 is disabled, and subject 9/type 8 is disabled and
lacks `accraw`. The pipeline must report these as missing/disabled rather than
failing or substituting another trial.

## Data and BoxSci contract

The Google Drive folder is a locally synchronized BoxSci dataset containing
`dbox_meta.mat`, `dbox_event.mat`, and lazy-loaded `data/*.mat` trial files. It
should be opened directly; the retained legacy `dbData.mat` should not be
re-imported.

```matlab
dbox = databox();
dbox.loadMeta(sDatasetPath);
```

The dataset path and BoxSci path must be runtime configuration inputs. Do not
retain the current hard-coded Windows `G:\...` paths.

Relevant signals in `accraw` are:

| Sensor | idSignal values | Signals |
| --- | --- | --- |
| FCU | 44-46 | `FCU_X`, `FCU_Y`, `FCU_Z` |
| FCR | 47-49 | `FCR_X`, `FCR_Y`, `FCR_Z` |
| ECU | 57-59 | `ECU_X`, `ECU_Y`, `ECU_Z` |

All have `nRate = 148.15 Hz`. Metadata units are volts, so plots must say
accelerometer signal (V), not g or m/s^2, unless a calibration is later supplied.
BoxSci signals use rows for signals/trials and columns for samples. In
particular, normalized multi-movement recall must remain
`[nMovement x nNormalizeSample]`.

Use current BoxSci APIs and helpers without modifying their stable contracts:

- `databox.loadMeta`, `getMeta`, `getSignal`, `getEvent`, `setEvent`, and
  `modEvent`
- `butterfilt` for zero-phase filtering
- `reportTemplate_run` for event-paired periods, time normalization, means,
  standard deviations, and counts
- `setPlot` to compose the requested subject-level layout and `printpdf` to
  export it

`reportTemplate_run` natively creates one axis per signal and overlays groups;
it does not create one tile per trial type. The reporting wrapper should call it
headlessly for each trial type/direction, reuse its returned statistics, and
compose a single subject figure with `setPlot`. This avoids changing BoxSci.

## Verified problems in the early scripts

The current scripts are useful exploration records but should not be extended
as the production pipeline.

1. `velocity_PlaceEvents_Horizontal.m` and
   `velocity_PlaceEvents_Vertical.m` collapse XYZ to a magnitude, rectify it,
   and integrate that nonnegative signal. This destroys axis sign before the
   code attempts to label left/right or up/down, doubles periodic components,
   and creates drift. The 92 signal-10 markers are not directly comparable to
   the 50 Touch markers: signal 10 contains an attempted onset and offset for
   each movement, while Touch contains attempted movement onsets only. The new
   analysis must evaluate onset timing separately from offset timing.
2. The scripts deactivate every event on `idSignalEvent = 10` and immediately
   save replacements. Signal 10 is `emgraw.FCU`, not an accelerometer, while
   trial metadata identifies Touch as signal 16. Horizontal and vertical
   scripts can overwrite each other's generic `on`/`off` events, so reruns are
   neither safe nor idempotent.
3. Time-to-index conversion omits MATLAB's `+1`, later offsets use `+nStart`
   instead of `+nStart-1`, and cross-sensor matching compares sample counts to
   seconds without multiplying by `nRate`.
4. `mod(numel(nevents),0)` uses a zero divisor where parity was intended, merge
   loops can index shorter arrays, and trials with fewer than two candidates
   can fail.
5. `burst_FitEvent.m` contains cross-sensor copy/paste errors (FCR statistics
   use FCU error; one FCR guard checks the ECU variable), brittle boundary
   indexing, a hard-coded trial correction, and an over-parameterized `sin8`
   fit in sample-index space. Its pointwise `rmse(...,1)` is not a scalar RMSE.
6. The scripts are monolithic, duplicate sensor/direction logic, depend on
   manually seeded generic events, contain many fixed thresholds, and have no
   automated tests or reproducible subject-level report.

## Proposed analysis

### 1. Select and validate the representative sensor

Use FCR as the initial candidate because the exploratory notes document a
signed horizontal FCR X convention and a signed vertical FCR Z convention.
Before fixing it for the cohort, score FCR, ECU, and FCU on every included trial
for:

- equal axis lengths, finite coverage, and nonconstant samples
- clipping/dropout and leading/trailing all-zero padding
- movement-to-baseline robust signal-to-noise ratio
- a cadence peak compatible with `nBeat`
- separation of the two alternating endpoint states on the relevant signed axis

Prefer one fixed sensor for every reported subject. A fallback is allowed only
when its horizontal/vertical axis sign mapping has been manually verified and
the report/QC table records the substitution. Never switch sensors silently.

### 2. Preprocess without losing direction

For the selected sensor, recall X/Y/Z at the native rate, trim only padding
identified across all three axes, and preserve the original time base. Apply a
zero-phase low-pass filter suitable for human reaching and estimate a slow
gravity/baseline component per axis. Keep both:

- signed, low-frequency axis information for endpoint and direction labeling
- a nonnegative 3-D dynamic-acceleration/jerk envelope for activity detection

Do not integrate a rectified vector magnitude. If a velocity-like coordinate is
needed for turnarounds, derive it from a signed dominant movement component,
remove drift with zero-phase filtering, and use it only as a timing proxy.

### 3. Detect all movement onsets around the beat

Estimate the observed cadence from the trial spectrum/autocorrelation and use
`60/nBeat` as the expected time from one movement onset to the next. Locate the
active movement bout, establish a high-confidence onset, and predict the onset
sequence at one-beat intervals. Refine every predicted onset to the nearest
supported feature in the signed movement coordinate and/or 3-D activity
envelope within a configurable fraction of the beat.

Onset detection is the primary timing problem. It should:

- find at most one accepted onset near each expected beat;
- retain the observed onset time rather than replacing it with an idealized
  metronome time;
- tolerate accumulated phase drift by updating the local beat estimate;
- flag a missing or low-confidence beat rather than shifting every subsequent
  event; and
- reject incomplete first/last movements when their boundaries cannot be
  supported by the signal.

Onset timing tolerance and cadence constraints should scale with the beat so
the same detector supports 120 bpm (0.5 s per movement) and 80 bpm (0.75 s per
movement).

BoxSci `getBurst` may be evaluated as a baseline candidate detector on the
nonnegative movement envelope, but its thresholding must meet the same test and
QC criteria before use.

### 4. Assign absolute direction

Classify each accepted traversal from the signed change/velocity proxy on the
relevant sensor axis, then alternate-check the result:

- horizontal trials: `right` or `left`
- vertical trials: `up` or `down`

The old comments propose positive FCR X as leftward and positive FCR Z as
downward. These are provisional label anchors, not established ground truth;
they must be confirmed on manually reviewed subject 6/type 10 data and at least
one vertical trial. The Touch events are useful independent timing references,
but their metadata does not identify which phase is right/left or up/down.

### 5. Detect and pair offsets after the onset sequence is fixed

Detect the end of each movement only after all accepted onsets have been
ordered. For an onset at `tOn(i)` and the following movement onset at
`tOn(i+1)`, search for endpoint stability or movement activity falling below
the offset threshold inside the inclusive interval:

```text
tOn(i) + 0.300 s <= tOff(i) <= tOn(i+1)
```

Thus every accepted movement must last at least 300 ms, and its offset may
coincide with but must never occur after the following movement onset. If no
earlier signal-supported offset is found, use the following onset itself as the
conservative offset and record this fallback in QC. If two accepted onsets are
less than 300 ms apart, the onset sequence is invalid and must be repaired or
the affected movement rejected; an offset must not be forced into an impossible
window. For the final onset, use a validated movement-bout end or reject the
incomplete final movement.

All directions may share the existing `off` event type. In BoxSci terminology,
`off` has `idEventType = 2`; `idEvent` is the identifier of an individual event
instance and should not be treated as the event-type code.

BoxSci's with-respect-to query links a generic offset to a custom onset by
trial, signal, and a time window. Because the upper bound is the actual next
onset and can vary between movements, query each onset with its own window (or
perform an equivalent batch query followed by the same validation):

```matlab
dtMax = tNextOn - tOn;
[tOff, ~, idOff] = dbox.getEvent(idTrial, idSignalRef, 'off', [], ...
    'wrtEvent', tOn, ...
    'wrtTrial', idTrial, ...
    'wrtPeriod', [0.300 dtMax], ...
    'bSingleColumn', true);
```

`wrtPeriod` is relative to `wrtEvent` and inclusive. BoxSci selects the closest
eligible `off` event within that window. Tests must verify that each accepted
onset resolves to exactly its intended offset and that no offset is reused by
two movements.

Return a movement table before touching dataset metadata. Each row should
include subject, trial type, trial, sensor, direction, onset, offset, duration,
cadence residual, onset and offset detector scores, acceptance flag, offset
fallback flag, and rejection/QC reason.

### 6. Store custom direction onsets and generic offsets

After review, define custom event types for movement onset direction:

- `reach_right_on`
- `reach_left_on`
- `reach_up_on`
- `reach_down_on`

Store every corresponding movement offset as the existing event type `off`
(`idEventType = 2`). Reports and downstream analyses will retrieve `off` with
respect to the relevant custom onset rather than assigning a direction-specific
offset type.

Associate horizontal events with the selected sensor's horizontal reference
axis and vertical events with its vertical reference axis. Adding the four
custom onset definitions requires appending rows to `metaEvent`; it does not
require a metadata column/schema change.

Writing must be an explicit second-stage operation:

1. Default to `ApplyEvents = false`.
2. Back up `dbox_meta.mat` and `dbox_event.mat` before the first approved write.
3. Add all events with `bSave = false`.
4. Validate counts, pairing, names, bounds, and repeatability in memory.
5. Delete all prior events from each targeted trial before adding the approved
   `reach_*_on` and generic `off` events.
6. Save once after validation, then reload and verify the round trip.

Never run event-writing tests against the live Google Drive dataset.

### 7. Normalize and report

For every custom direction onset and its with-respect-to generic `off`, use
`reportTemplate_run`/`getSignal` to recall the three selected accelerometer axes
and normalize each movement to a configurable grid (initially 201 samples,
0-100% movement time). Compute `mean(...,'omitnan')`, SD, and finite sample
count for each subject x trial type x direction x axis.

For each direction, configure the custom onset as `sTMinEvent`, configure
`off` as `sTMaxEvent`, and constrain `wrtPeriodMax` to start at 0.300 s. Because
`reportTemplate_run` accepts one period window per call, run it separately for
the relevant trial/direction and validate every returned period against the
actual following onset before including it in the mean.

Create one fixed 2-by-4 figure per subject, with tiles ordered by
`idTrialType = 7:14`. A missing/disabled trial gets a labeled empty tile. Each
available tile shows:

- X, Y, and Z means in consistent colors
- separate line styles for the two directions
- translucent +/-1 SD bands
- normalized movement time, voltage units, sensor name, trial type, pace, and
  accepted movement counts

Save the returned normalized arrays/statistics in MAT or tidy CSV form as well
as the figure PDF so the report is reproducible and numerically inspectable.

## Proposed code organization

Replace subject-specific scripts with small testable functions and one driver:

```text
runReachOrientationAnalysis.m       configuration and orchestration
loadReachOrientationTrial.m         BoxSci metadata/signal access
selectRepresentativeSensor.m        deterministic sensor QC/selection
detectReachMovements.m               pure XYZ-to-interval detector
classifyReachDirection.m             signed direction labeling
buildReachOrientationReport.m        BoxSci report/template integration
writeReachEvents.m                   guarded, idempotent commit stage
tests/TestReachOrientation.m         unit and integration tests
tests/fixtures/                       reviewed labels, not copied raw data
```

Detection and classification functions should accept numeric arrays and
metadata and return tables without file I/O. This makes algorithm tests fast
and prevents accidental writes.

## First integration test: subject 6 / trial type 10

The required test slice resolves uniquely to:

- `idSubject = 6`
- `idTrialType = 10` / `SIDE_HS`
- `idTrial = 40`
- `nBeat = 80`, expected beat interval 0.75 s
- `data/S06_2024_07_31_Trial40.mat`
- 8,726 samples per FCU/FCR/ECU axis at 148.15 Hz
- duration `(8726-1)/148.15 = 58.8930 s`
- four leading all-zero accelerometer samples

The existing Touch signal (id 16) has 50 enabled attempted movement-onset
markers from 10.164 to 47.617 s. Their median consecutive spacing is 0.7578 s.
Use them as the independent onset/cadence reference; they do not contain the
desired movement offsets and do not establish the absolute right/left labels.

The test will run with event commit disabled and verify:

1. metadata resolves exactly one enabled trial 40 and the chosen three axes
   have equal, finite, nonconstant data at the recorded rate;
2. custom direction onsets are finite, ordered, horizontal-only, and occur near
   successive 0.75 s beats without duplicate onsets at one beat;
3. direction labels alternate after missing/rejected onsets are accounted for;
4. onset count and timing are compatible with the 50 Touch onset markers and
   0.75 s cadence, using declared tolerances rather than exact raw-sample values;
5. a manually reviewed gold-standard subset meets a prespecified match rate and
   onset/offset timing tolerance (initial target: median absolute error no more
   than 0.10 s, revised only with documented justification);
6. each accepted onset has one generic `off` retrievable with respect to that
   onset, movement duration is at least 0.300 s, and the offset is no later than
   the following onset and is not reused by another movement;
7. normalized axis matrices are `[nMovement x 201]`, and returned mean, SD, and
   finite-count vectors are `1 x 201` with no infinite values;
8. headless report generation produces the type-10 tile; and
9. hashes/timestamps of the shared `dbox_meta.mat` and `dbox_event.mat` are
   unchanged.

Any event round-trip test will use a temporary dataset copy. BoxSci's full test
suite should also pass with:

```bash
matlab -batch "run('/path/to/boxsci/runTests.m');"
```

## Implementation and approval gates

1. **Plan review (current gate):** approve this README and the provisional FCR
   direction convention to test.
2. **Read-only prototype:** implement the pure detector, subject 6/type 10 test,
   candidate-event table, and QC/report output without changing Drive metadata.
3. **Prototype review:** manually confirm direction labels and timing on trial
   40, then tune only documented, cadence-scaled parameters.
4. **Cohort dry run:** process all 43 enabled subject/trial-type combinations,
   produce six subject figures and QC summaries, and investigate failures.
5. **Dataset commit review:** explicitly approve the candidate event set.
6. **Guarded commit:** back up, append the custom onset definitions, batch-write
   only approved `reach_*_on` and paired `off` events, save once, reload, and
   verify.
