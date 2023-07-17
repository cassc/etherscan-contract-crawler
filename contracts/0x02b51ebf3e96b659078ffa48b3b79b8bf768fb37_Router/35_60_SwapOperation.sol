// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

enum SwapOperation {
    EXACT_INPUT,
    EXACT_INPUT_ALL,
    EXACT_OUTPUT
}

error UnsupportedSwapOperation(SwapOperation);