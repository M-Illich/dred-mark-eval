# Evaluation for Delete/Rederive with Marking for Update Streams
This project allows for an evaluation of Delete/Rederive with Marking, which is an extension of the classical Delete/Rederive (DRed) algorithm with focus on processing streams of updates for a materialized dataset in Datalog.
The general idea of the evaluated approach is that we mark facts that are added or deleted by the next update in the stream, such that we can directly perform some computations that are relevant for the the next update without introducing additional rule applications and, thus, reduce the overall processing time of the stream.
Tests are provided for both synthetic and real data to compare the marking approach with classical DRed based on the needed CPU time, as well as the number of applied rule applications.
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
    java -jar dred-mark-eval-0.1.0.jar X Y Z
    ```
	where `X` has to be replaced by either `synthetic` or `real` to indicate what type of test data should be used. If  `X` is `synthetic`, then `Y` should be either `0` for the 'transitive paths' test case, or `1` for the 'sequential renaming' test case, respectively. If `X` is `real`, then `Y` should be either `0`, `1`, or `2` to indicate which predefined GPS track will be used to generate the test data. The value for `Z` should be either `0`, `1`, `2`, or `3`, where `0` means that a new random seed is used to generate the data for the synthetic tests, while each of the other values stands for one of three predefined random seeds to ensure reproducibility. The real tests are not affected by the value of `Z`.

3. Once the evaluation is finished, the measured CPU times and rule applications will be available in a `csv`-file in the folder `results`.
	

# Option 2: Execution with Docker
1. Call
    ```
    docker build -t eval .
    ```
    which will build a docker image with the name tag `eval`.
	
2. Run an evaluation with
    ```
    docker run --name=eval_container -e TYPE=X -e CASE=Y -e RND=Z eval
    ```
	where `X`, `Y`, and `Z` have to be replaced in the same way as explained above for the `jar` execution.
	
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
