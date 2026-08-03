package modelos;

public class FarmaciaSupervisor {

    private String name;
    private String centro;
    private String storeID;
    private String supervisor;

    public FarmaciaSupervisor() {
    }

    public FarmaciaSupervisor(String name, String centro, String storeID, String supervisor) {
        this.name = name;
        this.centro = centro;
        this.storeID = storeID;
        this.supervisor = supervisor;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getCentro() {
        return centro;
    }

    public void setCentro(String centro) {
        this.centro = centro;
    }

    public String getStoreID() {
        return storeID;
    }

    public void setStoreID(String storeID) {
        this.storeID = storeID;
    }

    public String getSupervisor() {
        return supervisor;
    }

    public void setSupervisor(String supervisor) {
        this.supervisor = supervisor;
    }
}