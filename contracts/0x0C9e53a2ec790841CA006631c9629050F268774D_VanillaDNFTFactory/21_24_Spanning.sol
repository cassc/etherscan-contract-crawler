// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (C) 2022 Spanning Labs Inc.

pragma solidity ^0.8.0;

import "./ISpanningDelegate.sol";
import "./SpanningUtils.sol";
import "./ISpanning.sol";

/**
 * @dev This module provides a number of utility functions and modifiers for
 * interacting with the Spanning Network.
 *
 * It includes:
 *  + Functions abstracting delegate state and methods
 *  + Functions for multi-domain ownership
 *
 * Note: This module is meant to be used through inheritance.
 */
abstract contract Spanning is ISpanning {
    // This allows us to efficiently unpack data in our Address specification.
    using SpanningAddress for bytes32;

    // Legacy address of the delegate for the current domain
    address private delegateLegacyAddress;

    // Reference to a Spanning Delegate interface
    ISpanningDelegate private delegate_;

    // Address of the owner of all contracts in this inheritance hierarchy
    bytes32 private rootOwner;

    /**
     * @dev Initializes a Spanning base module.
     *
     * Note: The initial rootOwner is set to the whomever deployed the contract.
     *
     * @param delegate - Legacy (local) address of our Spanning Delegate
     */
    constructor(address delegate) {
        delegateLegacyAddress = delegate;
        delegate_ = ISpanningDelegate(delegate);
        _transferOwnership(getAddressFromLegacy(msg.sender));
    }

    /**
     * @return bool - true if the contract is a Spanning contract
     */
    function isSpanning() external pure override returns (bool) {
        return true;
    }

    /**
     * @dev Reverts if the function is executed by anyone but the Delegate.
     */
    modifier onlySpanning() {
        require(isSpanningCall(), "onlySpanning: bad role");
        _;
    }

    /**
     * @return bool - true if a sender is a Spanning Delegate
     */
    function isSpanningCall() public view override returns (bool) {
        return (delegateAddress() == msg.sender);
    }

    /**
     * @return bytes4 - Domain identifier
     */
    function getDomain() internal view returns (bytes4) {
        return delegate_.getDomain();
    }

    /**
     * @return address - Local (legacy) address of the Delegate
     */
    function delegateAddress() internal view returns (address) {
        return delegateLegacyAddress;
    }

    /**
     * @dev Updates Delegate's legacy (local) address.
     *
     * @param newDelegateLegacyAddress - Desired address for Spanning Delegate
     */
    function updateDelegate(address newDelegateLegacyAddress)
        external
        override
        onlyOwner
    {
        require(newDelegateLegacyAddress != address(0), "Invalid Address");
        emit DelegateUpdated(delegateLegacyAddress, newDelegateLegacyAddress);
        delegateLegacyAddress = newDelegateLegacyAddress;
        delegate_ = ISpanningDelegate(newDelegateLegacyAddress);
    }

    /**
     * @dev Creates a function request for a delegate to execute.
     *
     * Note: This can result in either a local or cross-domain transaction.
     *
     * @param programAddress - Address to be called
     * @param payload - ABI-encoding of the desired function call
     */
    function makeRequest(bytes32 programAddress, bytes memory payload)
        internal
        virtual
    {
        delegate_.makeRequest(programAddress, payload);
    }

    /**
     * @dev Gets a Legacy Address from an Address, if in the same domain.
     *
     * Note: This function can be used to create backwards-compatible events.
     *
     * @param inputAddress - Address to convert to a Legacy Address
     *
     * @return address - Legacy Address if in the same domain, otherwise 0x0
     */
    function getLegacyFromAddress(bytes32 inputAddress)
        internal
        view
        returns (address)
    {
        address legacyAddress = address(0);
        if (inputAddress.getDomain() == delegate_.getDomain()) {
            legacyAddress = inputAddress.getAddress();
        }
        return legacyAddress;
    }

    /**
     * @dev Gets a Domain from an Address
     *
     * @param inputAddress - Address to convert to a domain
     *
     * @return domain -  Domain ID
     */
    function getDomainFromAddress(bytes32 inputAddress)
        internal
        pure
        returns (bytes4)
    {
        return inputAddress.getDomain();
    }

    /**
     * @dev Creates an Address from a Legacy Address, using the local domain.
     *
     * @param legacyAddress - Legacy (local) address to convert
     *
     * @return bytes32 - Packed Address
     */
    function getAddressFromLegacy(address legacyAddress)
        internal
        view
        returns (bytes32)
    {
        return SpanningAddress.create(legacyAddress, getDomain());
    }

    /**
     * @return bytes32 - Multi-domain msg.sender, defaulting to local sender.
     */
    function spanningMsgSender() internal view returns (bytes32) {
        if (delegate_.currentSenderAddress().valid()) {
            return delegate_.currentSenderAddress();
        }
        return getAddressFromLegacy(msg.sender);
    }

    /**
     * @return bytes32 - Multi-domain tx.origin, defaulting to local origin.
     */
    function spanningTxnSender() internal view returns (bytes32) {
        if (delegate_.currentTxnSenderAddress().valid()) {
            return delegate_.currentTxnSenderAddress();
        }
        return getAddressFromLegacy(tx.origin);
    }

    /**
     * @return bool - True if the current call stack has valid Spanning Info
     */
    function isValidSpanningInfo() internal view returns (bool) {
        return delegate_.isValidData();
    }

    /**
     * @return bytes32 - Multi-domain msg.sender, defaulting to local sender.
     */
    function spanningMsgSenderUnchecked() internal view returns (bytes32) {
        return delegate_.currentSenderAddress();
    }

    /**
     * @return bytes32 - Multi-domain tx.origin.
     */
    function spanningTxnSenderUnchecked() internal view returns (bytes32) {
        return delegate_.currentTxnSenderAddress();
    }

    /**
     * @dev Reverts if the function is executed by anyone but the owner.
     */
    modifier onlyOwner() {
        require(spanningMsgSender().equals(owner()), "onlyOwner: bad role");
        _;
    }

    /**
     * @return bytes32 - Address of current owner
     */
    function owner() public view virtual override returns (bytes32) {
        return rootOwner;
    }

    /**
     * @dev Sets the owner to null, effectively removing contract ownership.
     *
     * Note: It will not be possible to call `onlyOwner` functions anymore
     * Note: Can only be called by the current owner
     */
    function renounceOwnership() public virtual override onlyOwner {
        _transferOwnership(bytes32(0));
    }

    /**
     * @dev Assigns new owner for the contract.
     *
     * Note: Can only be called by the current owner
     *
     * @param newOwnerAddress - Address for desired owner
     */
    function transferOwnership(bytes32 newOwnerAddress)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwnerAddress != bytes32(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwnerAddress);
    }

    /**
     * @dev Transfers ownership of the contract to a new Address.
     *
     * @param newOwnerAddress - Address for desired owner
     */
    function _transferOwnership(bytes32 newOwnerAddress) internal virtual {
        bytes32 oldOwner = rootOwner;
        rootOwner = newOwnerAddress;
        emit OwnershipTransferred(oldOwner, newOwnerAddress);
    }
}