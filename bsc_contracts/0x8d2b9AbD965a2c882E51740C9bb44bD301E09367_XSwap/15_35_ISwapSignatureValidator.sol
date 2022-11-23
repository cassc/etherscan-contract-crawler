// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {Swap, SwapStep, StealthSwap} from "./Swap.sol";

interface ISwapSignatureValidator {
    function validateSwapSignature(Swap calldata swap, bytes calldata swapSignature) external view;

    function validateStealthSwapStepSignature(
        SwapStep calldata swapStep,
        StealthSwap calldata stealthSwap,
        bytes calldata stealthSwapSignature
    ) external view returns (uint256 stepIndex);

    function findStealthSwapStepIndex(
        SwapStep calldata swapStep,
        StealthSwap calldata stealthSwap
    ) external view returns (uint256 stepIndex);
}