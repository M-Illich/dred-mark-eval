package server;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.ServerSocket;
import java.net.Socket;

public class ExecutionServer {

	/**
	 * number of facts which are used to initialize the materialization
	 */
	final static int INITIAL_DATA_SIZE = 20;

	/**
	 * number of facts added to or deleted from the materialization in each update
	 */
	final static int UPDATE_SIZE = 2;

	/**
	 * length of update sequence provided in the stream
	 */
	final static int UPDATE_NUMBER = 10;

	public static void main(String[] args) {

		try {
			// open server
			ServerSocket serverSocket = new ServerSocket(8888);

			// execute prolog file
			ProcessBuilder pb = new ProcessBuilder();
			pb.command("cmd.exe", "/c", "cd src/main/resources && swipl -g init -t halt dred_mark.pl");
			Process prologCall = pb.start();

			// accept connection from prolog file
			Socket clientSocket = serverSocket.accept();

			PrintWriter out = new PrintWriter(clientSocket.getOutputStream(), true);
			BufferedReader in = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));
			
			
			/*
			 *  TODO
			 *  
			 *  different modes (?)
			 *  - get runtime of certain approach/file
			 *  - check correctness; compare outputs
			 *  ...
			 *  
			 */
			
			
			
			in.close();
			out.close();
			clientSocket.close();
			serverSocket.close();
			
			
			// read output from executed commands
			BufferedReader cmdReader = new BufferedReader(new InputStreamReader(prologCall.getInputStream()));
			String line;
			while ((line = cmdReader.readLine()) != null) {
				System.out.println(line);
			}
			cmdReader.close();
			

		} catch (IOException e) {
			e.printStackTrace();
		}

	}

}
