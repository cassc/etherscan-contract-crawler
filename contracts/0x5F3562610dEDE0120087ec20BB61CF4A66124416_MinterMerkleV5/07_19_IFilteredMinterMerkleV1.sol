// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "./IFilteredMinterMerkleV0.sol";

pragma solidity ^0.8.0;

/**
 * @title This interface extends the IFilteredMinterMerkleV0 interface in order
 * to add support for configuring and indexing the delegation registry address.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterMerkleV1 is IFilteredMinterMerkleV0 {
    /**
     * @notice Notifies of the contract's configured delegation registry
     * address.
     */
    event DelegationRegistryUpdated(address delegationRegistryAddress);
}