package data;

import java.util.Set;

public class Update {

	public Set<Fact> added;
	public Set<Fact> deleted;

	public Update(Set<Fact> add, Set<Fact> delete) {
		this.added = add;
		this.deleted = delete;
	}

	/**
	 * Transform an update {@code ([F1(a1,a2), F2(a3), ...],[F3(a4,...),...])} into
	 * a String {@code [[F1,a1,a2],[F2,a3],...]:[[F3,a4,...],...]}
	 */
	public String toString() {
		return added.toString() + ":" + deleted.toString();
	}

}
