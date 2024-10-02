package graph;

import java.util.Set;

public class Update {

	Set<Fact> add;
	Set<Fact> delete;

	public Update(Set<Fact> add, Set<Fact> delete) {
		this.add = add;
		this.delete = delete;
	}

	/**
	 * Transform an update {@code ([F1(a1,a2), F2(a3), ...],[F3(a4,...),...])} into
	 * a String {@code [[F1,a1,a2],[F2,a3],...]:[[F3,a4,...],...]}
	 */
	public String toString() {
		return add.toString() + ":" + delete.toString();
	}

}
