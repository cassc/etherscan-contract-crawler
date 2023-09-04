// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '@violetprotocol/mauve-periphery/contracts/base/SelfPermit.sol';
import '@violetprotocol/mauve-periphery/contracts/base/PeripheryImmutableState.sol';

import './interfaces/IMauveSwapRouter.sol';
import './SwapRouter.sol';
import './base/ApproveAndCall.sol';

/// @title Mauve Swap Router
contract MauveSwapRouter is IMauveSwapRouter, SwapRouter, ApproveAndCall, SelfPermit {
    constructor(
        address factory,
        address _positionManager,
        address _WETH9,
        address _EATVerifier
    ) ImmutableState(_positionManager) PeripheryImmutableState(factory, _WETH9) EATMulticall(_EATVerifier) {}
}