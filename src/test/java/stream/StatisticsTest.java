package stream;

import static org.junit.Assert.assertEquals;

import java.util.LinkedList;

import org.junit.Test;

public class StatisticsTest {
	
	@Test
	public void testIntegrateData() {
		// test input
		LinkedList<String> data = new LinkedList<>();
		data.add("applied_rules(297,ins)");
		data.add("applied_rules(491,del)");
		data.add("applied_rules(548,red)");
		data.add("marked_facts(305,add)");
		data.add("marked_facts(16,del)");
		data.add("% 3,440,308 inferences, 0.313 CPU in 0.332 seconds (94% CPU, 11008986 Lips)");
		
				
		Statistics stats = new Statistics();
		stats.integrateData(data);
		
		// check stored data
		assertEquals(297, stats.appliedRules.get("ins").intValue());
		assertEquals(491, stats.appliedRules.get("del").intValue());
		assertEquals(548, stats.appliedRules.get("red").intValue());
		assertEquals(305, stats.markedFacts.get("add").intValue());
		assertEquals(16, stats.markedFacts.get("del").intValue());
		assertEquals(0.332f, stats.runtime, 0.0001f);
		
	}

}
