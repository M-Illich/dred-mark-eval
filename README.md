# Evaluation for Delete/Rederive with Marking for Update Streams
This project allows for an evaluation of Delete/Rederive with Marking, which is an extension of the classical Delete/Rederive (DRed) algorithm with focus on processing streams of updates for a materialized dataset in Datalog.
The general idea of the evaluated approach is that we mark facts that are added or deleted by the next update in the stream, such that we can directly perform some computations that are relevant for the the next update without introducing additional rule applications and, thus, reduce the overall processing time of the stream.
Tests are provided for both synthetic and real data to compare the marking approach with classical DRed based on the needed CPU time, as well as the number of applied rule applications.
The selection and execution of the tests is done in the `Evaluation`-class.

# Prerequisites: 
- [Java v.22](https://www.oracle.com/java/technologies/downloads/) and [Maven v3.9.9](https://maven.apache.org/)
- [SWI-Prolog v.9.3.15](https://www.swi-prolog.org/Download.html)
