// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Owner
/// @notice Transferrable owner authorization pattern.
abstract contract Owner {

    ///===========================
    /// STATE
    ///===========================

    /// @notice Emitted when the ownership is changed
    /// @param previousOwner Previous owner of the contract.
    /// @param newOwner New owner of the contract.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Current owner of the contract.
    address public owner;

    ///@notice Modifier to verify that the sender is the owner of the contract.
    modifier onlyOwner() {
        require (msg.sender == owner, "NOT_OWNER");
        _;
    }

    ///===========================
    /// INIT
    ///===========================

    ///@notice Initially set the owner as the contract deployer.
    constructor() {
        _transferOwnership(msg.sender);
    }

    ///===========================
    /// FUNCTIONS
    ///===========================

    /// @notice Transfer the ownership of the contract.
    /// @param newOwner Address ownership is to be transferred to.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }

    ///===========================
    /// INTERNAL
    ///===========================

    /// @notice Transfer the ownership of the contract.
    /// @param newOwner Address ownership is to be transferred to.
    function _transferOwnership(address newOwner) internal {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
}