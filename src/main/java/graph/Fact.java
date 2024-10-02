package graph;

import java.util.LinkedList;
import java.util.List;

public class Fact {

	String predicate;
	List<String> arguments;

	public Fact(String predicate, List<String> arguments) {
		this.predicate = predicate;
		this.arguments = arguments;
	}

	/**
	 * Transforms fact {@code f(a1,a2,...)} into a String {@code [f,a1,a2,...]}
	 */
	public String toString() {
		LinkedList<String> factList = new LinkedList<>(arguments);
		factList.addFirst(predicate);
		return factList.toString();
	}

	@Override
	public boolean equals(Object f) {
		return this.toString().equals(f.toString());

	}

	@Override
	public int hashCode() {
		return this.toString().hashCode();
	}
	
}