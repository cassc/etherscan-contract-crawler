// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

library HelioswapConstants {
    uint256 internal constant _FEE_DENOMINATOR = 1e18;

    uint256 internal constant _MIN_DECAY_PERIOD = 1 minutes;

    uint256 internal constant _MAX_FEE = 0.01e18; // 1%
    uint256 internal constant _MAX_SLIPPAGE_FEE = 1e18;  // 100%
    uint256 internal constant _MAX_DECAY_PERIOD = 5 minutes;

    uint256 internal constant _DEFAULT_FEE = 3e15; // 0.3%
    uint256 internal constant _DEFAULT_SLIPPAGE_FEE = 466e15;  // 46.6%
    uint256 internal constant _DEFAULT_DECAY_PERIOD = 1 minutes;
}