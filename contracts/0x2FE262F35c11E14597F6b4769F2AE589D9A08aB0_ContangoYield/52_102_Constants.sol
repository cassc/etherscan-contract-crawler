// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

/// @dev only necessary constants from https://github.com/notional-finance/contracts-v2/blob/master/contracts/global/Constants.sol
library Constants {
    // Token precision used for all internal balances, TokenHandler library ensures that we
    // limit the dust amount caused by precision mismatches
    int256 internal constant INTERNAL_TOKEN_PRECISION = 1e8;
    // Number of decimal places that rates are stored in, equals 100%
    int256 internal constant RATE_PRECISION = 1e9;
}