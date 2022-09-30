// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../external/@openzeppelin/token/ERC20/IERC20.sol";

/// @title Common Spool contracts constants
abstract contract BaseConstants {
    /// @dev 2 digits precision
    uint256 internal constant FULL_PERCENT = 100_00;

    /// @dev Accuracy when doing shares arithmetics
    uint256 internal constant ACCURACY = 10**30;
}

/// @title Contains USDC token related values
abstract contract USDC {
    /// @notice USDC token contract address
    IERC20 internal constant USDC_ADDRESS = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
}