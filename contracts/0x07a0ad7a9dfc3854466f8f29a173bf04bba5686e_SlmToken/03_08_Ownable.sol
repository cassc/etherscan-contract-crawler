// SPDX-License-Identifier: MIT
pragma solidity ~0.8.0;

/// @title Ownable
/// @dev The Ownable contract has an owner address, and provides basic authorization control
/// functions, this simplifies the implementation of "user permissions".
contract Ownable {
    address _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev Set the original `_owner` of the contract to the sender account.
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    /// @dev Allows the current owner to transfer control of the contract to a newOwner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Don't assign ownership to null address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}