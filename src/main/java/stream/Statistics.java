package stream;

import java.util.Collection;
import java.util.HashMap;

public class Statistics {

	/**
	 * number of applied rules for each DRed phase
	 */
	HashMap<String, Integer> appliedRules;

	/**
	 * number of marked facts for each type
	 */
	HashMap<String, Integer> markedFacts;

	/**
	 * measured exeuction time needed to complete processing of update stream
	 */
	float executionTime;

	/**
	 * measured CPU time needed to complete processing of update stream
	 */
	float cpuTime;

	public Statistics() {
		appliedRules = new HashMap<>();
		markedFacts = new HashMap<>();
		executionTime = 0;
	}

	public void integrateData(Collection<String> data) {
		for (String string : data) {
			integrateData(string);
		}
	}

	public void integrateData(String data) {
		// check for applied rules
		if (data.startsWith("a")) {
			// format = applied_rules(123,red)
			String[] args = data.substring(14, data.length() - 1).split(",");
			// store data
			appliedRules.putIfAbsent(args[1], Integer.parseInt(args[0]));
		}
		// check for marked facts
		else if (data.startsWith("m")) {
			// format = marked_facts(305,add)
			String[] args = data.substring(13, data.length() - 1).split(",");
			// store data
			markedFacts.putIfAbsent(args[1], Integer.parseInt(args[0]));
		}
		// check for runtime
		else if (data.startsWith("%")) {
			// format = % 252,760,468 inferences, 22.625 CPU in 47.675 seconds
			// extract CPU time
			cpuTime = Float.parseFloat(data.substring(data.indexOf("s, ") + 3, data.indexOf(" CPU")));
			// extract execution time
			executionTime = Float.parseFloat(data.substring(data.indexOf("in ") + 3, data.indexOf(" sec")));

		}

	}

}
