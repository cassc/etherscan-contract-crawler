// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "../MultiStakerCurveBPAMO.sol";

/// @title ConvexAgEURvEUROCAMO
/// @author Angle Core Team
/// @notice Implements ConvexBPAMO for the pool agEUR-EUROC
contract MultiStakerCurveAgEURvEUROCAMO is MultiStakerCurveBPAMO {
    IStakeCurveVault private constant _stakeDAOVault = IStakeCurveVault(0xDe46532a49c88af504594F488822F452b7FBc7BD);
    ILiquidityGauge private constant _liquidityGauge = ILiquidityGauge(0x63f222079608EEc2DDC7a9acdCD9344a21428Ce7);
    IConvexBaseRewardPool private constant _convexBaseRewardPool =
        IConvexBaseRewardPool(0xA91fccC1ec9d4A2271B7A86a7509Ca05057C1A98);
    uint256 private constant _convexPoolPid = 113;

    /// @inheritdoc MultiStakerCurveBPAMO
    function _vault() internal pure override returns (IStakeCurveVault) {
        return _stakeDAOVault;
    }

    /// @inheritdoc MultiStakerCurveBPAMO
    function _gauge() internal pure override returns (ILiquidityGauge) {
        return _liquidityGauge;
    }

    /// @inheritdoc MultiStakerCurveBPAMO
    function _baseRewardPool() internal pure override returns (IConvexBaseRewardPool) {
        return _convexBaseRewardPool;
    }

    /// @inheritdoc MultiStakerCurveBPAMO
    function _poolPid() internal pure override returns (uint256) {
        return _convexPoolPid;
    }
}