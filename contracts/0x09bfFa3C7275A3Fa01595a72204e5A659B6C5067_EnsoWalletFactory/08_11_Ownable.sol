// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../libraries/StorageAPI.sol";

// @notice The OWNER slot must be set in the importing contract's constructor or initialize function
abstract contract Ownable {
    using StorageAPI for bytes32;

    // Using same slot generation technique as eip-1967 -- https://eips.ethereum.org/EIPS/eip-1967
    bytes32 internal constant OWNER = bytes32(uint256(keccak256("enso.access.owner")) - 1);
    bytes32 internal constant PENDING_OWNER = bytes32(uint256(keccak256("enso.access.pendingOwner")) - 1);

    event OwnershipTransferred(address previousOwner, address newOwner);
    event OwnershipTransferStarted(address previousOwner, address newOwner);

    error NotOwner();
    error NotPermitted();
    error InvalidAccount();

    modifier onlyOwner {
        if (msg.sender != OWNER.getAddress()) revert NotOwner();
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert InvalidAccount();
        address currentOwner = OWNER.getAddress();
        if (newOwner == currentOwner) revert InvalidAccount();
        PENDING_OWNER.setAddress(newOwner);
        emit OwnershipTransferStarted(currentOwner, newOwner);
    }

    function acceptOwnership() external {
        if (msg.sender != PENDING_OWNER.getAddress()) revert NotPermitted();
        PENDING_OWNER.setAddress(address(0));
        address previousOwner = OWNER.getAddress();
        OWNER.setAddress(msg.sender);
        emit OwnershipTransferred(previousOwner, msg.sender);
    }

    function owner() external view returns (address) {
        return OWNER.getAddress();
    }
}