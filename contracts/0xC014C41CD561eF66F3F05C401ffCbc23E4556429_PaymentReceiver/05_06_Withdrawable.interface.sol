// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

abstract contract WithdrawableInterface {
    
    // ==== General Contract Admin ====

    function addAdmin(address adminAddress) external virtual;

    function removeAdmin(address adminAddress) external virtual;

    // ==== Core Contract Functionality ====

    function withdraw() external virtual;
}