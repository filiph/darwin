## 0.6.0-dev

- BREAKING: rename `IsolateTask.MAX_INT` to `IsolateTask.maxInt`
- BREAKING: rename `IsolateWorker.MAX_QUEUE` to `IsolateWorker.maxQueueLength`
- BREAKING: rename `MultithreadedPhenotypeSerialEvaluator.BATCH_SIZE` to `MultithreadedPhenotypeSerialEvaluator.batchSize`

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
