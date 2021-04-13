# darwin

[![Build Status](https://travis-ci.org/filiph/darwin.svg?branch=master)](https://travis-ci.org/filiph/darwin)

A genetic/evolutionary algorithm library for Dart. Given a population 
of phenotypes, an evaluator (fitness function), and time, the algorithm
will evolve the population until it crosses given fitness threshold.

[Read more](https://en.wikipedia.org/wiki/Genetic_algorithm) 
about genetic algorithms on Wikipedia.

Features of this library:

* Generic approach (anything can be a gene, as long as it can mutate)
* User can tune crossover probability, mutation rate, mutation strength, etc.
* Niching via [fitness sharing](http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.33.8352&rep=rep1&type=pdf)
* Multi-objective optimization via [Pareto rank](http://www.eng.auburn.edu/sites/personal/aesmith/files/publications/journal/Multi-objective%20optimization%20using%20genetic%20algorithms.pdf)
* Experimental support for multi-threaded computation

For an up-to-date example use, please see `example/example.dart`.
