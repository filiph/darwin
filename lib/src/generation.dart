part of darwin;

class Generation<T extends Phenotype> {
  List<T> members = new List<T>();

  num cummulativeFitness;
  num get averageFitness {
    if (cummulativeFitness == null) return null;
    return cummulativeFitness / members.length;
  }

  num bestFitness;

  /**
   * Computes [cummulativeFitness] and [bestFitness], assuming all members of
   * the population are scored.
   */
  void computeSummary() {
    cummulativeFitness = 0;
    bestFitness = double.INFINITY;
    members.forEach((T ph) {
      cummulativeFitness += ph.result;
      if (ph.result < bestFitness) {
        bestFitness = ph.result;
        best = ph;
      }
    });
  }

  T best;
}
