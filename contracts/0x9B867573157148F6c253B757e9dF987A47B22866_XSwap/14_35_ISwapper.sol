// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {Swap, StealthSwap, SwapStep} from "./Swap.sol";

/**
 * @dev Correlation with EIP-2612 permit:
 *
 * > address token -> Permit.token
 * > address owner -> SwapStep.account
 * > address spender -> xSwap contract
 * > uint256 value -> Permit.amount
 * > uint256 deadline -> Permit.deadline
 * > uint8 v -> Permit.signature
 * > bytes32 r -> Permit.signature
 * > bytes32 s -> Permit.signature
 *
 * The Permit.resolver is address of a contract responsible
 * for applying permit ({IPermitResolver}-compatible)
 */
struct Permit {
    address resolver;
    address token;
    uint256 amount;
    uint256 deadline;
    bytes signature;
}

struct Call {
    address target;
    bytes data;
}

struct SwapParams {
    Swap swap;
    bytes swapSignature;
    uint256 stepIndex;
    Permit[] permits;
    uint256[] inAmounts;
    Call call;
    bytes[] useArgs;
}

struct StealthSwapParams {
    StealthSwap swap;
    bytes swapSignature;
    SwapStep step;
    Permit[] permits;
    uint256[] inAmounts;
    Call call;
    bytes[] useArgs;
}

interface ISwapper {
    function swap(SwapParams calldata params) external payable;

    function swapStealth(StealthSwapParams calldata params) external payable;
}