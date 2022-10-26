// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    address private _owner;

    /**
        @dev emitted when ownership is transfered 
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
        @dev creates a contract instance and sets deployer as its _owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
        @dev returns address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
        @dev checks if caller of the function is _owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "You are not the owner");
        _;
    }

    /**
       @dev transfers the ownership to 0x00 address.
       @notice after renouncing contract ownership functions with onlyOwner modifier will not be accessible.
       @notice can be called only be _owner
    */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
        @dev transfers ownership to newOwner.
        @notice can not be transfered to 0x00 addres.
        @notice can be called only be _owner
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "zero address can not be owner");
        _transferOwnership(newOwner);
    }

    /**
        @dev internal function to transfer ownership.
        @notice can only be called internally and only by _owner.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}