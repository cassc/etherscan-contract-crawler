//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Lib Allowlist Masks
/// @notice Holds all the mask values
library LibAllowlistMasks {
    /// @notice Mask used for denied accounts
    uint256 internal constant DENY_MASK = 0x1 << 255;
    /// @notice The mask for the deposit right
    uint256 internal constant DEPOSIT_MASK = 0x1;
    /// @notice The mask for the donation right
    uint256 internal constant DONATE_MASK = 0x1 << 1;
    /// @notice The mask for the redeem right
    uint256 internal constant REDEEM_MASK = 0x1 << 2;
}