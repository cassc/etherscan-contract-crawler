// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address internal backupOwner;
    mapping(address => bool) public isGovernor;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
        backupOwner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == backupOwner);
        _;
    }

    modifier onlyGovernors() {
        require(
            isGovernor[msg.sender] == true ||
                msg.sender == owner ||
                msg.sender == backupOwner,
            "Not a governor."
        );
        _;
    }

    function setBackupOwner(address _backupOwner) public {
        require(msg.sender == owner);
        backupOwner = _backupOwner;
    }

    function giveGovernance(address governor) public onlyOwner {
        isGovernor[governor] = true;
    }

    function revokeGovernance(address governor) public onlyOwner {
        isGovernor[governor] = false;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}