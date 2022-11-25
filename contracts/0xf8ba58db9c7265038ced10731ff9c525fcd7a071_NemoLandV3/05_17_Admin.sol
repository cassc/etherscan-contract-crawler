// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Admin {
    address internal admin_;

    /// @dev Emits when the contract admin is changed.
    /// @param oldAdmin Address of the previous admin.
    /// @param newAdmin Address of the new admin.
    event AdminChanged(address oldAdmin, address newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin_, "ONLY ADMIN");
        _;
    }

    /// @dev Get current admin of this contract.
    /// @return current admin of this contract.
    function getAdmin() external view returns (address) {
        return admin_;
    }

    /// @dev Change the admin to be `newAdmin`.
    /// @param newAdmin address of the new admin.
    function changeAdmin(address newAdmin) external {
        require(msg.sender == admin_, "NOT AN ADMIN, ACCESS DENIED");
        admin_ = newAdmin;
        emit AdminChanged(admin_, newAdmin);
    }
}