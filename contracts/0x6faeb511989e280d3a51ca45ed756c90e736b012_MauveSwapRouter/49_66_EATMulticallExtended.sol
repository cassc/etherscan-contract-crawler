// SPDX-License-Identifier: GPL-2.0-or-later
pragma abicoder v2;
pragma solidity =0.7.6;

import '@violetprotocol/mauve-periphery/contracts/base/EATMulticall.sol';

import '../interfaces/IEATMulticallExtended.sol';
import '../base/PeripheryValidationExtended.sol';

/// @title EATMulticallExtended
/// @notice Adds multicalls with deadlines and previous blockhash checks
abstract contract EATMulticallExtended is IEATMulticallExtended, EATMulticall, PeripheryValidationExtended {
    /// @inheritdoc IEATMulticallExtended
    function multicall(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 expiry,
        uint256 deadline,
        bytes[] calldata data
    ) external payable override checkDeadline(deadline) returns (bytes[] memory) {
        return multicall(v, r, s, expiry, data);
    }

    /// @inheritdoc IEATMulticallExtended
    function multicall(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 expiry,
        bytes32 previousBlockhash,
        bytes[] calldata data
    ) external payable override checkPreviousBlockhash(previousBlockhash) returns (bytes[] memory) {
        return multicall(v, r, s, expiry, data);
    }
}