// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import {LibCurve} from "../libs/LibCurve.sol";
import {Modifiers} from "../libs/LibAppStorage.sol";

import {ICurveFacet} from "../interfaces/ICurveFacet.sol";

/// @title MeTokens Curve Facet
/// @author @cartercarlson, @zgorizzo69, @cbobrobison, @parv3213
/// @notice This contract provides direct    views to the meTokens Protocol curve.
contract CurveFacet is Modifiers, ICurveFacet {
    /// @inheritdoc ICurveFacet
    function viewMeTokensMinted(
        uint256 assetsDeposited,
        uint256 hubId,
        uint256 supply,
        uint256 balancePooled
    ) external view override returns (uint256) {
        return
            LibCurve.viewMeTokensMinted(
                assetsDeposited,
                hubId,
                supply,
                balancePooled
            );
    }

    /// @inheritdoc ICurveFacet
    function viewTargetMeTokensMinted(
        uint256 assetsDeposited,
        uint256 hubId,
        uint256 supply,
        uint256 balancePooled
    ) external view override returns (uint256) {
        return
            LibCurve.viewTargetMeTokensMinted(
                assetsDeposited,
                hubId,
                supply,
                balancePooled
            );
    }

    /// @inheritdoc ICurveFacet
    function viewAssetsReturned(
        uint256 meTokensBurned,
        uint256 hubId,
        uint256 supply,
        uint256 balancePooled
    ) external view override returns (uint256) {
        return
            LibCurve.viewAssetsReturned(
                meTokensBurned,
                hubId,
                supply,
                balancePooled
            );
    }

    /// @inheritdoc ICurveFacet
    function viewTargetAssetsReturned(
        uint256 meTokensBurned,
        uint256 hubId,
        uint256 supply,
        uint256 balancePooled
    ) external view override returns (uint256) {
        return
            LibCurve.viewTargetAssetsReturned(
                meTokensBurned,
                hubId,
                supply,
                balancePooled
            );
    }

    /// @inheritdoc ICurveFacet
    function getCurveInfo(uint256 hubId)
        external
        view
        override
        returns (LibCurve.CurveInfo memory)
    {
        return LibCurve.getCurveInfo(hubId);
    }
}