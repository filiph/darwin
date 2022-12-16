## 0.7.0

- Fix wrong polarity of `dominates()`
- BREAKING: Make list of `Generation.members` final
- BREAKING: `evaluateLastGeneration` --> `evaluateLatestGeneration`

## 0.6.0

- Update to conform latest Dart style and `pkg:lints`
  - BREAKING: `IsolateTask.MAX_INT` is now `IsolateTask.maxInt`
  - BREAKING: `IsolateWorker.MAX_QUEUE` is now `IsolateWorker.maxQueue`
  - BREAKING: `MultithreadedPhenotypeSerialEvaluator.BATCH_SIZE` is now
    `MultithreadedPhenotypeSerialEvaluator.batchSize`
- Replace wrong usage of `Null` with the correct `void`
- Fix non-standard name of constructor (`MyPhenotype.Random`) in example

## 0.5.1

- Make sure README links to `https` URLs (as per pub.dev guidelines)

## 0.5.0

- BREAKING: Null Safety migration
- BREAKING: fixed typo in `GenerationBreeder.propability` to `.probability`
- BREAKING: fixed typo in `Evaluator.cummulative` to `.cumulative`
- BREAKING: fixed typo in `Generation.cummulativeFitnes` to `.cumulativeFitness`
- BREAKING: changed `ALL_CAPS_FIELDS` into the more idiomatic `camelCaseFields`
  - `GeneticAlgorithm.MAX_EXPERIMENTS` to `thresholdResult`
  - `GeneticAlgorithm.MAX_GENERATIONS_IN_MEMORY` to `maxGenerationsInMemory`

## 0.4.2

- Resolve implicit cast problem
- Remove optional `new` and `const`
- Apply modern Dart formatting

## 0.4.1

- Upgrade to Dart 2
