package stream;


public class Main {

	
	public static void main(String[] args) {
		
		String file = "dred_mark.pl";
		long randomSeed = 123456;
		int maxNodeNumber = 10;
		int initialDataSize = 20;
		int updateSize = 5;
		int numberOfUpdates = 10;

		UpdateStreamRun usr = new UpdateStreamRun(file, randomSeed, maxNodeNumber, initialDataSize, updateSize, numberOfUpdates);
		usr.execute(true, true, true);
		
		
		
		/*
		 *  TODO
		 *  
		 *  make several (random?) runs and compute average of times
		 *  
		 *  -- command output --
applied_rules(297,ins)
applied_rules(548,red)
applied_rules(491,del)
marked_facts(305,add)
marked_facts(6,del)
% 3,440,308 inferences, 0.313 CPU in 0.332 seconds (94% CPU, 11008986 Lips)
		 * 
		 */
		
		
		

	}


}
