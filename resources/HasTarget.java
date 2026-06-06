package d4j.ant;

import org.apache.tools.ant.ProjectComponent;
import org.apache.tools.ant.taskdefs.condition.Condition;

public class HasTarget extends ProjectComponent implements Condition {
    private String name;

    public void setName(String name) {
        this.name = name;
    }

    public boolean eval() {
        return getProject().getTargets().containsKey(name);
    }
}
