// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Withdrawable.interface.sol";

abstract contract Withdrawable is WithdrawableInterface {

    // ==== Variables ====

    mapping(address => bool) private admins;
    uint256 public adminCount;

    // ======== Constructor =========
    
    constructor() {
        // The address that creates the contract becomes it's first admin
         admins[msg.sender] = true;
         adminCount = 1;
    }

    // ======== Events =========

    event Received(address, uint256);

    // ==== Modifiers ====

    modifier onlyAdmins() {
        require(admins[msg.sender], "Admin access only");
        _;
    }

    // ==== General Contract Admin ====

    function addAdmin(address walletAddress) external override onlyAdmins {
        if (admins[walletAddress]) {
            return;
        }
        admins[walletAddress] = true;
        adminCount += 1;
    }

    function removeAdmin(address walletAddress) external override onlyAdmins {
        if (!admins[walletAddress]) {
            return;
        }
        require(adminCount > 1, "Contract needs at least one admin");
        delete admins[walletAddress];
        adminCount -= 1;
    }

    // ==== Core Contract Functionality ====

    function withdraw() external override onlyAdmins {
        uint256 balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Withdraw failed");
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}