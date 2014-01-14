part of darwin;

abstract class Phenotype<T> {
  List<T> genes;
  num result = null;
  num _resultWithFitnessSharingApplied = null;
  
//  Phenotype<T> clone() {
//    Phenotype<T> copy = new Phenotype<T>();
//    copy.genes = new List<T>.from(genes, growable: false);
//  }
  
  T mutateGene(T gene, num strength);
  
  toString() => "Phenotype<$genesAsString>";
  
  String get genesAsString => JSON.encode(genes);
  
  /**
   * Returns the degree to which this chromosome has dissimilar genes with the
   * other. If chromosomes are identical, returns [:0.0:]. If all genes are 
   * different, returns [:1.0:].
   * 
   * Genes are considered different when they are not equal. There is no
   * half-different gene (which would make sense for [num] genes, for example).
   */
  num computeHammingDistance(Phenotype<T> other) {
    int length = genes.length;
    int similarCount = 0;
    for (int i = 0; i < genes.length; i++) {
      if (genes[i] == other.genes[i]) {
        similarCount++;
      }
    }
    return (1 - similarCount / length);
  }
}