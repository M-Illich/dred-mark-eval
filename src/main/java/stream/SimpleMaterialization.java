package stream;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.Set;

import graph.Fact;

public class SimpleMaterialization extends StreamToProlog {

	/**
	 * name of Prolog file where materialization approach is saved
	 */
	public String file;
	
	/**
	 * dataset for which the materialization has to be created
	 */
	public Set<Fact> dataset;

	/**
	 * materialized dataset
	 */
	public Set<Fact> materialization;

	public SimpleMaterialization(String file, Set<Fact> dataset) {
		this.file = file;
		this.dataset = dataset;
	}

	/**
	 * 
	 * @return materialization of the caller's dataset
	 */
	public Set<Fact> execute() {

		try {
			// open server
			ServerSocket serverSocket = new ServerSocket(0);

			// execute prolog file
			callProlog(serverSocket.getLocalPort(), file);

			// accept connection from prolog file
			Socket clientSocket = serverSocket.accept();

			PrintWriter out = new PrintWriter(clientSocket.getOutputStream(), true);
			BufferedReader in = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));

			// provide dataset over stream
			out.println(dataset.toString());

			// read materialization
			materialization = readAnswers(in, false).getFirst();

			in.close();
			out.close();
			clientSocket.close();
			serverSocket.close();

		} catch (IOException e) {
			e.printStackTrace();
		}

		return materialization;

	}

}
