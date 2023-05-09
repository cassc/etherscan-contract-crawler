/**
 *Submitted for verification on 2023-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// This contract defines an owner, which can be transferred or renounced, and provides a modifier to restrict access to owner-only functionality.
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // The constructor sets the initial owner as the deployer of the contract.
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    // Returns the current owner of the contract.
    function owner() public view returns (address) {
        return _owner;
    }

    // A modifier that requires the sender to be the current owner of the contract.
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    // Allows the current owner to relinquish control of the contract.
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    // Allows the current owner to transfer control of the contract to a new owner.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}