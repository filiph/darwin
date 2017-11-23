darwin
======

A genetic/evolutionary algorithm library for Dart. Given a population 
of phenotypes, an evaluator (fitness function), and time, the algorithm
will evolve the population until it crosses given fitness threshold.

[Read more](https://en.wikipedia.org/wiki/Genetic_algorithm) 
about genetic algorithms on Wikipedia.

Features of this library:

* Generic approach (anything can be a gene, as long as it can mutate)
* User can tune crossover probability, mutation rate, mutation strength, etc.
* Niching via fitness sharing
* Experimental support for multithreaded computation

For up-to-date example use, please see `example/example.dart`.
