package stream;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Set;
import java.util.concurrent.TimeUnit;

import data.Fact;
import data.Update;

public class RealUpdateStreamRun extends StreamToProlog {

	/**
	 * name of file containing SWI-Prolog code to be executed
	 */
	String file;

	/**
	 * name of folder where each stream update is stored as file
	 */
	String updateFolder;

	/**
	 * states if there should be a delay between updates based on real GPS time
	 * points
	 */
	boolean realDelay;

	/**
	 * list of answer sets for each stated query
	 */
	public List<Set<Fact>> queryAnswers;

	/**
	 * list of datasets created by sequence of updates
	 */
	public List<Set<Fact>> datasets;

	/**
	 * information about number of applied rules, marked facts, and runtime
	 */
	public Statistics statistics;

	/**
	 * Fixed update size.
	 * 
	 * @param file         {@code String} name of file containing SWI-Prolog code to
	 *                     be executed
	 * @param updateFolder {@code String} name of folder where each stream update is
	 *                     stored as file
	 * @param realDelay    {@code boolean} stating if there should be a delay
	 *                     between updates based on real GPS time points
	 */
	public RealUpdateStreamRun(String file, String updateFolder, boolean realDelay) {
		this.file = file;
		this.updateFolder = updateFolder;
		this.realDelay = realDelay;
		this.statistics = new Statistics();

	}

	/**
	 * Process a stream of updates that adapt a graph by adding and deleting edges.
	 * The updates are created randomly based on the caller's attributes. The Prolog
	 * code in {@code file} incrementally maintains the materialization of the graph
	 * by computing the transitive closure of paths comprising connected edges.
	 * 
	 * @param printUpdates         {@code boolean} states if updates and their
	 *                             overlap with direct predecessor are printed to
	 *                             standard output
	 * 
	 * @param printMaterialization {@code boolean} states if materialization
	 *                             obtained after each update is printed to standard
	 *                             output
	 * 
	 * @param printStatistics      {@code boolean} states if number of applied rules
	 *                             and runtime is printed to standard output
	 * 
	 */
	public void execute(boolean printUpdates, boolean printMaterialization, boolean printStatistics) {

		try {
			// open server
			ServerSocket serverSocket = new ServerSocket(0);

			// execute prolog file
			Process prologCall = callProlog(serverSocket.getLocalPort(), file);

			// accept connection from prolog file
			Socket clientSocket = serverSocket.accept();

			PrintWriter out = new PrintWriter(clientSocket.getOutputStream(), true);
			BufferedReader in = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));

			// create stream based on updates stored in update folder
			datasets = createUpdateStream(out, printUpdates);

			// read answers for each query
			queryAnswers = readAnswers(in, printMaterialization);

			in.close();
			out.close();
			clientSocket.close();
			serverSocket.close();

			// read output from executed commands
			BufferedReader cmdReader = new BufferedReader(new InputStreamReader(prologCall.getInputStream()));
			if (printStatistics) {
				System.out.println("-- command output --");
			}
			statistics.integrateData(readOutput(cmdReader, printStatistics));
			cmdReader.close();
			// get additional messages, like execution time if available
			BufferedReader cmdError = new BufferedReader(new InputStreamReader(prologCall.getErrorStream()));
			statistics.integrateData(readOutput(cmdError, printStatistics));
			cmdError.close();

		} catch (IOException e) {
			e.printStackTrace();
		}

	}

	/**
	 * Create a stream based on the predefined updates in {@code updateFolder}. A
	 * query asking for every fact is stated after each update.
	 * 
	 * 
	 * @param out          {@link PrintWriter} to write updates to stream
	 * @param printUpdates {@code boolean} states if updates and their overlap with
	 *                     direct predecessor are printed to standard output
	 * @return a list of sets of facts representing the sequence of datasets created
	 *         by the update stream
	 */
	List<Set<Fact>> createUpdateStream(PrintWriter out, boolean printUpdates) {

		List<Set<Fact>> datasets = new LinkedList<>();
		Set<Fact> dataset = new HashSet<>();

		// store previous update to compute overlap
		Update pre = new Update(new HashSet<>(), new HashSet<>());
		HashSet<Fact> replaced_del = new HashSet<>();
		HashSet<Fact> replaced_add = new HashSet<>();
		Update u;

		// create stream based on updates stored as files
		File[] updateFiles = new File(updateFolder).listFiles();
		for (int i = 1; i <= updateFiles.length; i++) {
			// read update from file
			u = readUpdate(updateFiles[i - 1]);

			// store updated explicit dataset
			dataset.addAll(u.added);
			dataset.removeAll(u.deleted);
			datasets.add(new HashSet<Fact>(dataset));

			if (printUpdates) {
				replaced_del.clear();
				replaced_add.clear();
				// determine overlap with previous update
				for (Fact fact : u.added) {
					if (pre.deleted.contains(fact)) {
						replaced_del.add(fact);
					}
				}
				for (Fact fact : u.deleted) {
					if (pre.added.contains(fact)) {
						replaced_add.add(fact);
					}
				}
				// store current update for next overlap
				pre = u;

				// print update
				System.out.println("");
				String[] us = u.toString().split(":");
				System.out.println(i + ": " + us[0]);
				System.out.println("   " + us[1]);
				// print size of overlap with previous update
				System.out.println(" Overlap with previous: replaced del = " + replaced_del.size()
						+ " - replaced add = " + replaced_add.size());
			}

			// delay stream according to GPS point time
			if (realDelay && i > 1) {
				try {
					TimeUnit.SECONDS.sleep(getTimeSeconds(updateFiles[i - 1]) - getTimeSeconds(updateFiles[i - 2]));
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
			}

			// write update to stream
			out.println(u.toString());

			// insert query directly after each update (asking for every fact)
			out.println("X:");
			if (printUpdates) {
				System.out.println("query " + i);
			}

		}

		// indicate end of stream
		out.println("[]:[]");

		return datasets;

	}

	/**
	 * Get time in seconds that is stated in the name of the file in the format
	 * {@code HH.MM.SS}.
	 * 
	 * @param file a {@link File} containing an update
	 * @return {@code long} seconds
	 */
	long getTimeSeconds(File file) {
		String name = file.getName();
		String timeString = name.substring(name.lastIndexOf("T") + 1, name.lastIndexOf("Z"));

		// time format = "HH.MM.SS"
		long hours = Long.valueOf(timeString.substring(0, 2));
		long min = Long.valueOf(timeString.substring(3, 5));
		long sec = Long.valueOf(timeString.substring(6));
		long seconds = hours * 3600 + min * 60 + sec;

		return seconds;
	}

	/**
	 * Create an update based on a file that explicitly states which facts have to
	 * be added and deleted.
	 * 
	 * @param file {@link File} containing in each line either
	 *             {@code add(p(a1, a2))} or {@code delete(p(a1, a2))} for any
	 *             Datalog fact {@code p(a2, a2)}
	 * @return {@link Update} with {@code add} and {@code delete} sets based on file
	 */
	Update readUpdate(File file) {

		Set<Fact> addFacts = new HashSet<>();
		Set<Fact> deleteFacts = new HashSet<>();

		BufferedReader reader;
		try {
			reader = new BufferedReader(new FileReader(file));
			String line = reader.readLine();

			while (line != null) {
				if (line.startsWith("add")) {
					addFacts.add(new Fact(line.substring(4, line.length() - 2)));
				} else if (line.startsWith("delete")) {
					deleteFacts.add(new Fact(line.substring(7, line.length() - 2)));
				}
				line = reader.readLine();
			}

			reader.close();

		} catch (Exception e) {
			e.printStackTrace();
		}

		return new Update(addFacts, deleteFacts);

	}

}
