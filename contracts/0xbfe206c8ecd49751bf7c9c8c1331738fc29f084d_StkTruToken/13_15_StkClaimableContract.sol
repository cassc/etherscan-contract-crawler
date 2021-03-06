// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ProxyStorage} from "ProxyStorage.sol";

/**
 * @title ClaimableContract
 * @dev The ClaimableContract contract is a copy of Claimable Contract by Zeppelin.
 and provides basic authorization control functions. Inherits storage layout of
 ProxyStorage.
 */
contract StkClaimableContract is ProxyStorage {
    function owner() public view returns (address) {
        return owner_;
    }

    function pendingOwner() public view returns (address) {
        return pendingOwner_;
    }

    event OwnershipTransferred(address indexed currentOwner, address indexed newPendingOwner);
    event OwnershipClaimed(address indexed currentOwner, address indexed newOwner);

    /**
     * @dev sets the original `owner` of the contract to the sender
     * at construction. Must then be reinitialized
     */
    constructor() {
        owner_ = msg.sender;
        emit OwnershipClaimed(address(0), msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner_, "only owner");
        _;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner_);
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner_ = newOwner;
        emit OwnershipTransferred(owner_, newOwner);
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public onlyPendingOwner {
        address _pendingOwner = pendingOwner_;
        emit OwnershipClaimed(owner_, _pendingOwner);
        owner_ = _pendingOwner;
        pendingOwner_ = address(0);
    }
}