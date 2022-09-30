// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import {LibCurve} from "../libs/LibCurve.sol";

/// @title meTokens Protocol Curve Facet interface
/// @author Carter Carlson (@cartercarlson), @zgorizzo69
interface ICurveFacet {
    /// @notice Get curveInfo for a hub
    /// @param hubId Unique hub identifier
    /// @return CurveInfo of hub
    function getCurveInfo(uint256 hubId)
        external
        view
        returns (LibCurve.CurveInfo memory);

    /// @notice Calculate meTokens minted based on a curve's active details
    /// @param assetsDeposited  Amount of assets deposited to the hub
    /// @param hubId            Unique hub identifier
    /// @param supply           Current meToken supply
    /// @param balancePooled    Area under curve
    /// @return meTokensMinted  Amount of MeTokens minted
    function viewMeTokensMinted(
        uint256 assetsDeposited,
        uint256 hubId,
        uint256 supply,
        uint256 balancePooled
    ) external view returns (uint256 meTokensMinted);

    /// @notice Calculate assets returned based on a curve's active details
    /// @param meTokensBurned   Amount of assets deposited to the hub
    /// @param hubId            Unique hub identifier
    /// @param supply           Current meToken supply
    /// @param balancePooled    Area under curve
    /// @return assetsReturned  Amount of assets returned
    function viewAssetsReturned(
        uint256 meTokensBurned,
        uint256 hubId,
        uint256 supply,
        uint256 balancePooled
    ) external view returns (uint256 assetsReturned);

    /// @notice Calculate meTokens minted based on a curve's target details
    /// @param assetsDeposited  Amount of assets deposited to the hub
    /// @param hubId            Unique hub identifier
    /// @param supply           Current meToken supply
    /// @param balancePooled    Area under curve
    /// @return meTokensMinted  Amount of MeTokens minted
    function viewTargetMeTokensMinted(
        uint256 assetsDeposited,
        uint256 hubId,
        uint256 supply,
        uint256 balancePooled
    ) external view returns (uint256 meTokensMinted);

    /// @notice Calculate assets returned based on a curve's target details
    /// @param meTokensBurned   Amount of assets deposited to the hub
    /// @param hubId            Unique hub identifier
    /// @param supply           Current meToken supply
    /// @param balancePooled    Area under curve
    /// @return assetsReturned  Amount of assets returned
    function viewTargetAssetsReturned(
        uint256 meTokensBurned,
        uint256 hubId,
        uint256 supply,
        uint256 balancePooled
    ) external view returns (uint256 assetsReturned);
}