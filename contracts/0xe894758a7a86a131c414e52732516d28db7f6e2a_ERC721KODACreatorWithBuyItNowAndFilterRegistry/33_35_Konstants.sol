// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract Konstants {
    /// @notice Maximum Platform Commission for Primary and Secondary Sales
    /// @dev precision 100.00000%
    uint24 public constant MAX_PLATFORM_COMMISSION = 50_00000;

    /// @notice Maximum Royalty Percentage for Secondary Sales
    /// @dev precision 100.00000%
    uint24 public constant MAX_ROYALTY_PERCENTAGE = 50_00000;

    /// @notice Denominator used for percentage calculations
    /// @dev precision 100.00000%
    uint24 public constant MODULO = 100_00000;
}