// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '@violetprotocol/ethereum-access-token/contracts/AccessTokenConsumer.sol';
import '../interfaces/IEATMulticall.sol';
import './Multicall.sol';

enum CallState {IDLE, IS_MULTICALLING, IS_CALLING_PROTECTED_FUNCTION}

/// @title Ethereum Access Token Multicall
/// @notice Enables calling multiple methods in a single call to the contract using
/// EATs for access control
abstract contract EATMulticall is Multicall, IEATMulticall, AccessTokenConsumer {
    constructor(address _EATVerifier) AccessTokenConsumer(_EATVerifier) {}

    // track call state for re-entrancy protection
    CallState internal _callState;

    modifier multicalling() {
        _callState = CallState.IS_MULTICALLING;
        _;
        _callState = CallState.IDLE;
    }

    // be careful with external contract function calls made by functions you modify with this
    // keep in mind possible re-entrancy
    modifier onlySelfMulticall {
        // Requires to be in a multicall
        // NSMC -> Not self multi calling
        CallState callState = _callState;
        if (callState == CallState.IDLE) revert('NSMC');

        // Prevents cross-function re-entrancy
        // CFL -> Cross Function Lock
        if (callState != CallState.IS_MULTICALLING) revert('CFL');

        _callState = CallState.IS_CALLING_PROTECTED_FUNCTION;
        _;
        _callState = CallState.IS_MULTICALLING;
    }

    /// @inheritdoc IEATMulticall
    function multicall(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 expiry,
        bytes[] calldata data
    ) public payable override requiresAuth(v, r, s, expiry) multicalling() returns (bytes[] memory results) {
        // performs an external call to self for core multicall logic
        return super.multicall(data);
    }

    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata) public payable override returns (bytes[] memory) {
        // NED -> non-EAT multicall disallowed
        revert('NED');
    }
}