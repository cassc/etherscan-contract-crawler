// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

/// @title Interface of the contract managing perpetuals with claim function
/// @author Angle Core Team
/// @dev Front interface with rewards function, meaning only user-facing functions
interface IPerpetualManagerFrontWithClaim {
    function getReward(uint256 perpetualID) external;

    function addToPerpetual(uint256 perpetualID, uint256 amount) external;

    function openPerpetual(
        address owner,
        uint256 amountBrought,
        uint256 amountCommitted,
        uint256 maxOracleRate,
        uint256 minNetMargin
    ) external returns (uint256 perpetualID);
}