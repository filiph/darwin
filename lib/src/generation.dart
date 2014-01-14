part of darwin;

class Generation<T extends Phenotype> {
  List<T> members = new List<T>();
  
  /**
   * Filters the generation to phenotypes that are similar to [ph] as defined
   * by their Hamming distance being less than [radius].
   * 
   * This _includes_ the original [ph] (Because [ph]'s Hamming distance to 
   * itself is [:0:].)
   */
  Iterable<T> getSimilarPhenotypes(T ph, num radius) {
    return members
        .where((T candidate) => ph.computeHammingDistance(candidate) < radius);
  }
  
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
      if (ph.result < bestFitness) bestFitness = ph.result;
    });
  }
}