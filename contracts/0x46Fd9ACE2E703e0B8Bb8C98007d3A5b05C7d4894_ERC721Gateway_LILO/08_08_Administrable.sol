pragma solidity ^0.8.0;

contract Administrable {
    address public admin;
    address public pendingAdmin;
    event LogSetAdmin(address admin);
    event LogTransferAdmin(address oldadmin, address newadmin);
    event LogAcceptAdmin(address admin);

    function setAdmin(address admin_) internal {
        admin = admin_;
        emit LogSetAdmin(admin_);
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        address oldAdmin = pendingAdmin;
        pendingAdmin = newAdmin;
        emit LogTransferAdmin(oldAdmin, newAdmin);
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
        emit LogAcceptAdmin(admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
}