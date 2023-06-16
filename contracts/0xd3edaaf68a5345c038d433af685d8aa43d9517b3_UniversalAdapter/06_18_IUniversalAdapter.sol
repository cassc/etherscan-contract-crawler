// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { IAdapter } from "./IAdapter.sol";

struct RevocationPair {
    address spender;
    address token;
}

/// @title Universal adapter interface
/// @notice Implements the initial version of universal adapter, which handles allowance revocations
interface IUniversalAdapter is IAdapter {
    /// @notice Revokes allowances for specified spender/token pairs
    /// @param revocations Spender/token pairs to revoke allowances for
    function revokeAdapterAllowances(RevocationPair[] calldata revocations)
        external;
}