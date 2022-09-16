// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

/// @title IOracleCore
/// @author Angle Core Team
interface IOracleCore {
    function readUpper() external view returns (uint256);

    function readQuoteLower(uint256 baseAmount) external view returns (uint256);
}