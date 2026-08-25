package modelos;

import java.sql.Timestamp;

public class SolicitudTarjetaPlus {

    private String orderCode;
    private String cardSku;
    private String tipoTarjeta;
    private String fullName;
    private String identityDocument;
    private String email;
    private String phone;
    private Timestamp birthdate;
    private String locationDepartment;
    private String locationCity;
    private String locationAddress;

    public SolicitudTarjetaPlus() {
    }

    public String getOrderCode() {
        return orderCode;
    }

    public void setOrderCode(String orderCode) {
        this.orderCode = orderCode;
    }

    public String getCardSku() {
        return cardSku;
    }

    public void setCardSku(String cardSku) {
        this.cardSku = cardSku;
    }

    public String getTipoTarjeta() {
        return tipoTarjeta;
    }

    public void setTipoTarjeta(String tipoTarjeta) {
        this.tipoTarjeta = tipoTarjeta;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getIdentityDocument() {
        return identityDocument;
    }

    public void setIdentityDocument(String identityDocument) {
        this.identityDocument = identityDocument;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public Timestamp getBirthdate() {
        return birthdate;
    }

    public void setBirthdate(Timestamp birthdate) {
        this.birthdate = birthdate;
    }

    public String getLocationDepartment() {
        return locationDepartment;
    }

    public void setLocationDepartment(String locationDepartment) {
        this.locationDepartment = locationDepartment;
    }

    public String getLocationCity() {
        return locationCity;
    }

    public void setLocationCity(String locationCity) {
        this.locationCity = locationCity;
    }

    public String getLocationAddress() {
        return locationAddress;
    }

    public void setLocationAddress(String locationAddress) {
        this.locationAddress = locationAddress;
    }
}
