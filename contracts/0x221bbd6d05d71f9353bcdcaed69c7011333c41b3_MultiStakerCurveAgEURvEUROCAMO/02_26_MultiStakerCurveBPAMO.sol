// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "../../../interfaces/external/convex/IBooster.sol";
import "../../../interfaces/external/convex/IBaseRewardPool.sol";
import "../../../interfaces/external/convex/IClaimZap.sol";
import "../../../interfaces/external/convex/ICvxRewardPool.sol";
import "../../../interfaces/external/stakeDAO/IStakeCurveVault.sol";
import "../../../interfaces/external/stakeDAO/IClaimerRewards.sol";
import "../../../interfaces/external/stakeDAO/ILiquidityGauge.sol";

import "../curve/BaseCurveBPAMO.sol";

/// @title MultiStakerCurveBPAMO
/// @author Angle Core Team
/// @notice AMO depositing tokens on a Curve pool and staking the LP tokens on both StakeDAO and Convex
abstract contract MultiStakerCurveBPAMO is BaseCurveBPAMO {
    uint256 private constant _BASE_PARAMS = 10**9;

    /// @notice Convex-related constants
    IConvexBooster private constant _convexBooster = IConvexBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    IConvexClaimZap private constant _convexClaimZap = IConvexClaimZap(0xDd49A93FDcae579AE50B4b9923325e9e335ec82B);

    /// @notice Define the proportion of the AMO controlled by stakeDAO `amo`
    uint256 public stakeDAOProportion;

    // // if we want to accept a loss when withdrawing
    // uint256 private constant _MAX_LOSS = 10**6;

    uint256[49] private __gapMultiStakerCurveBPAMO;

    // =================================== ERRORS ==================================

    error WithdrawFeeTooLarge();

    // =============================== INITIALIZATION ==============================

    /// @notice Initializes the `AMO` contract
    function initialize(
        address amoMinter_,
        IERC20 agToken_,
        address basePool_
    ) external {
        _initializeBaseCurveBPAMO(amoMinter_, agToken_, basePool_);
    }

    // =================================== SETTER ==================================

    /// @notice Sets the proportion of the LP tokens that should be staked on StakeDAO with respect
    /// to Convex
    function setStakeDAOProportion(uint256 _newProp) external onlyApproved {
        if (_newProp > _BASE_PARAMS) revert IncompatibleValues();
        stakeDAOProportion = _newProp;
    }

    // ============================= INTERNAL ACTIONS ==============================

    /// @inheritdoc BaseCurveAMO
    /// @dev In this implementation, Curve LP tokens are deposited into StakeDAO and Convex
    function _depositLPToken() internal override {
        uint256 balanceLP = IERC20(mainPool).balanceOf(address(this));

        // Compute what should go to Stake and Convex respectively
        uint256 lpForStakeDAO = (balanceLP * stakeDAOProportion) / _BASE_PARAMS;
        uint256 lpForConvex = balanceLP - lpForStakeDAO;

        if (lpForStakeDAO > 0) {
            // Approve the vault contract for the Curve LP tokens
            _changeAllowance(IERC20(mainPool), address(_vault()), lpForStakeDAO);
            // Deposit the Curve LP tokens into the vault contract and stake
            _vault().deposit(address(this), lpForStakeDAO, true);
        }

        if (lpForConvex > 0) {
            // Deposit the Curve LP tokens into the convex contract and stake
            _changeAllowance(IERC20(mainPool), address(_convexBooster), lpForConvex);
            _convexBooster.deposit(_poolPid(), lpForConvex, true);
        }
    }

    /// @notice Withdraws the Curve LP tokens from StakeDAO and Convex
    function _withdrawLPToken() internal override {
        uint256 lpInStakeDAO = _stakeDAOLPStaked();
        uint256 lpInConvex = _convexLPStaked();
        if (lpInStakeDAO > 0) {
            if (_vault().withdrawalFee() > 0) revert WithdrawFeeTooLarge();
            _vault().withdraw(lpInStakeDAO);
        }
        if (lpInConvex > 0) _baseRewardPool().withdrawAllAndUnwrap(true);
    }

    /// @inheritdoc BaseAMO
    /// @dev Governance is responsible for handling CRV, SDT, and CVX rewards claimed through this function
    /// @dev Rewards can be used to pay back part of the debt by swapping it for `agToken`
    /// @dev Currently this implementation only supports the Liquidity gauge associated to the StakeDAO Curve vault
    /// @dev Should there be any additional reward contract for Convex or for StakeDAO, we should add to the list
    /// the new contract
    function _claimRewards(IERC20[] memory) internal override returns (uint256) {
        // Claim on StakeDAO
        _gauge().claim_rewards(address(this));
        // Claim on Convex
        address[] memory rewardContracts = new address[](1);
        rewardContracts[0] = address(_baseRewardPool());

        _convexClaimZap.claimRewards(
            rewardContracts,
            new address[](0),
            new address[](0),
            new address[](0),
            0,
            0,
            0,
            0,
            0
        );
        return 0;
    }

    // ========================== INTERNAL VIEW FUNCTIONS ==========================

    /// @inheritdoc BaseCurveAMO
    function _balanceLPStaked() internal view override returns (uint256) {
        return _convexLPStaked() + _stakeDAOLPStaked();
    }

    /// @notice Get the balance of the Curve LP tokens staked on StakeDAO for the pool
    function _stakeDAOLPStaked() internal view returns (uint256) {
        return _gauge().balanceOf(address(this));
    }

    /// @notice Get the balance of the Curve LP tokens staked on Convex for the pool
    function _convexLPStaked() internal view returns (uint256) {
        return _baseRewardPool().balanceOf(address(this));
    }

    // ============================= VIRTUAL FUNCTIONS =============================
    
    /// @notice StakeDAO Vault address
    function _vault() internal pure virtual returns (IStakeCurveVault);

    /// @notice StakeDAO gauge address
    function _gauge() internal pure virtual returns (ILiquidityGauge);

    /// @notice Address of the Convex contract on which to claim rewards
    function _baseRewardPool() internal pure virtual returns (IConvexBaseRewardPool);

    /// @notice ID of the pool associated to the AMO on Convex
    function _poolPid() internal pure virtual returns (uint256);
}