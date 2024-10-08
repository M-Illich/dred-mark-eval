package stream;


public class Main {

	
	public static void main(String[] args) {
		
		String file = "dred_no_mark.pl";
		long randomSeed = 1234;
		int maxNodeNumber = 10;
		int initialDataSize = 10;
		int updateSize = 5;
		int numberOfUpdates = 10;

		UpdateStreamRun usr = new UpdateStreamRun(file, randomSeed, maxNodeNumber, initialDataSize, updateSize, numberOfUpdates);
		usr.execute(true, true, true);

	}


}
