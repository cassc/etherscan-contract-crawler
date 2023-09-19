// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title  Role-based access control inspired by CryptoKitties
/// @dev    Keep the CEO wallet stored offline, I warned you.
/// @author William Entriken (https://phor.net)
abstract contract AccessControlTwoOfficers {
    /// @notice The account that can only reassign officer accounts
    address public executiveOfficer;

    /// @notice The account that can collect funds from this contract
    address payable public financialOfficer;

    constructor() {
        executiveOfficer = msg.sender;
    }

    /// @notice Reassign the executive officer role
    /// @param  newExecutiveOfficer new officer address
    function setExecutiveOfficer(address newExecutiveOfficer) external {
        require(msg.sender == executiveOfficer);
        require(newExecutiveOfficer != address(0));
        executiveOfficer = newExecutiveOfficer;
    }

    /// @notice Reassign the financial officer role
    /// @param  newFinancialOfficer new officer address
    function setFinancialOfficer(address payable newFinancialOfficer) external {
        require(msg.sender == executiveOfficer);
        require(newFinancialOfficer != address(0));
        financialOfficer = newFinancialOfficer;
    }

    /// @notice Collect funds from this contract
    function withdrawBalance() external {
        require(msg.sender == financialOfficer);
        financialOfficer.transfer(address(this).balance);
    }
}