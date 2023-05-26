// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Owned
 * @notice Basic contract to define an owner.
 */
contract Owned {

    // The owner
    address public owner;

    event OwnerChanged(address indexed _newOwner);

    /**
     * @notice Throws if the sender is not the owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner, "O: Must be owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Lets the owner transfer ownership of the contract to a new owner.
     * @param _newOwner The new owner.
     */
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "O: Address must not be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
}