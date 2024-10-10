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
	 * measured time needed to complete processing of update stream
	 */
	float runtime;

	public Statistics() {
		appliedRules = new HashMap<>();
		markedFacts = new HashMap<>();
		runtime = 0;
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
			// format = ... 0.313 CPU in 0.332 seconds ...
			String str = data.substring(data.indexOf("in ") + 3, data.indexOf(" sec"));
			// store data
			runtime = Float.parseFloat(str);

		}

	}

}
