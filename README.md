# Evaluation of Delete/Rederive and Backward/Forward with Marking for Update Streams
This project allows for an evaluation of both Delete/Rederive and Backward/Forward with Marking, which are extensions of the classical [Delete/Rederive](https://doi.org/10.1145/170035.170066) (DRed)  and [Backward/Forward](https://doi.org/10.1609/aaai.v29i1.9409) (B/F) algorithms with focus on processing streams of updates for a materialized dataset in Datalog.
The general idea of the evaluated approach is that we mark facts that are added or deleted by the next update in the stream, such that we can directly perform some computations that are relevant for the the next update without introducing additional rule applications and, thus, reduce the overall processing time of the stream.
Tests are provided for both synthetic and real data to compare the marking approach with the classical algorithms based on the needed CPU time, as well as the number of applied rule applications.
The selection and execution of the tests is done in the `Evaluation`-class.

# Prerequisites: 
- [Java v.22](https://www.oracle.com/java/technologies/downloads/) and [Maven v3.9.9](https://maven.apache.org/)
- [SWI-Prolog v.9.3.15](https://www.swi-prolog.org/Download.html) or [Docker](https://www.docker.com)

# Preparations
1. Clone the repository
   ```
   git clone https://github.com/M-Illich/dred-mark-eval
   ```

2. Go to the root directory of the repository and install the maven project with the following command
    ```
    mvn clean package
    ```
	which will generate a `jar` file located in the same folder. 
	

# Option 1: Execution with SWI-Prolog
1. Ensure that SWI-Prolog is correctly installed with
	```
    swipl --version
    ```
	
2. Execute the `jar` file with 	
	```
    java -jar dred-mark-eval-0.1.0.jar A T C R
    ```
	where `A` has to be replaced by either `dred` or `bf` to determine the considered algorithm, and `T` by either `synthetic` or `real` to indicate what type of test data should be used. If  `T` is `synthetic`, then `C` should be either `0` for the 'transitive paths' test case, or `1` for the 'sequential renaming' test case, respectively. If `T` is `real`, then `C` should be either `0`, `1`, or `2` to indicate which predefined GPS track will be used to generate the test data. The value for `R` should be either `0`, `1`, `2`, or `3`, where `0` means that a new random seed is used to generate the data for the synthetic tests, while each of the other values stands for one of three predefined random seeds to ensure reproducibility. The real tests are not affected by the value of `R`.

3. Once the evaluation is finished, the measured CPU times and counted rule applications will be available in a `csv`-file in the folder `results`.
	

# Option 2: Execution with Docker
1. Call
    ```
    docker build -t eval .
    ```
    which will build a docker image with the name tag `eval`.
	
2. Run an evaluation with
    ```
    docker run --name=eval_container -e ALGO=A -e TYPE=T -e CASE=C -e RND=R eval
    ```
	where `A`, `T`, `C`, and `R` have to be replaced in the same way as explained above for the `jar` execution.
	
3. Copy measured results from docker container	
   ```
    docker cp eval_container:app/results .
    ```

----------------------------------------------------------------------------------------------

Copyright 2025 Moritz Illich

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
