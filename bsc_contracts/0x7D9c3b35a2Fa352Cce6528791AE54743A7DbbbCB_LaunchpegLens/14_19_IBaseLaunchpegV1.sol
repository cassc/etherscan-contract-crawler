// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IBaseLaunchpegV1
/// @author Trader Joe
/// @notice Defines the legacy methods in Launchpeg V1 contracts
interface IBaseLaunchpegV1 {
    /** IBaseLaunchpeg */
    function projectOwner() external view returns (address);

    /** ILaunchpeg */
    function getAllowlistPrice() external view returns (uint256);

    function getPublicSalePrice() external view returns (uint256);

    /** IBatchReveal */
    function revealBatchSize() external view returns (uint256);

    function lastTokenRevealed() external view returns (uint256);

    function revealStartTime() external view returns (uint256);

    function revealInterval() external view returns (uint256);
}