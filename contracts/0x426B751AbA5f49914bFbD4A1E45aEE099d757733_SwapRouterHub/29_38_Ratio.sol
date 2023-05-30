// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library Ratio {
    uint160 internal constant MIN_SQRT_RATIO_PLUS_ONE = 4295128739 + 1;
    uint160 internal constant MAX_SQRT_RATIO_MINUS_ONE = 1461446703485210103287273052203988822378723970342 - 1;
}