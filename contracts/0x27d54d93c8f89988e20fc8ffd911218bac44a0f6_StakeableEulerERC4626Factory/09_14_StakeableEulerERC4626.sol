// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {IEulerEToken} from "../external/IEulerEToken.sol";
import {IRewardsDistribution} from "../external/IRewardsDistribution.sol";
import {IStakingRewards} from "../external/IStakingRewards.sol";

import {EulerERC4626} from "../EulerERC4626.sol";

/// @title StakeableEulerERC4626
/// @author Sam Bugs
/// @notice A ERC4626 wrapper for Euler Finance, that can handle staking
contract StakeableEulerERC4626 is EulerERC4626, Owned {

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    /// @notice Thrown when trying to assign an invalid rewards contract
    error StakeableEulerERC4626__InvalidRewardContract();

    /// -----------------------------------------------------------------------
    /// Libraries usage
    /// -----------------------------------------------------------------------

    using SafeTransferLib for ERC20;

    /// -----------------------------------------------------------------------
    /// Immutable params
    /// -----------------------------------------------------------------------

    /// @notice The rewards distribution address
    IRewardsDistribution public immutable rewardsDistribution;

    /// -----------------------------------------------------------------------
    /// Mutable params
    /// -----------------------------------------------------------------------

    /// @notice The staking rewards address
    IStakingRewards public stakingRewards;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(ERC20 asset_, address euler_, IEulerEToken eToken_, IRewardsDistribution rewardsDistribution_, address owner_)
        EulerERC4626(asset_, euler_, eToken_)
        Owned(owner_)
    {
        rewardsDistribution = rewardsDistribution_;
    }

    /// -----------------------------------------------------------------------
    /// ERC4626 overrides
    /// -----------------------------------------------------------------------

    function totalAssets() public view virtual override returns (uint256) {
        uint256 eTokenStakedBalance = _getStakedBalance();
        if (eTokenStakedBalance > 0) {
            // We add all eToken balance (staked and non-staked) and then convert to underlying
            // We do this to prevent rounding differences if we converted to underlying and then added the results
            uint256 eTokenBalanceInContract = eToken.balanceOf(address(this));
            return eToken.convertBalanceToUnderlying(eTokenStakedBalance + eTokenBalanceInContract);
        }
        return eToken.balanceOfUnderlying(address(this));
    }

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual override {
        uint256 underlyingBalanceInContract = eToken.balanceOfUnderlying(address(this));
        if (underlyingBalanceInContract < assets) {
            // Need to unstake to meet the demand
            uint256 neededUnderlying = assets - underlyingBalanceInContract;
            uint256 neededEToken = eToken.convertUnderlyingToBalance(neededUnderlying);

            // We also withdraw 5% of remaining staked eTokens so that we can avoid unstaking again in the next withdraw
            uint256 eTokenStakedBalance = _getStakedBalance();
            uint256 remaining = eTokenStakedBalance - neededEToken;
            uint256 withdrawAttempt = neededEToken + FixedPointMathLib.mulDivUp(remaining, 5, 100);

            // We make sure we don't try to withdraw more than available
            uint256 toWithdraw = eTokenStakedBalance < withdrawAttempt ? eTokenStakedBalance : withdrawAttempt;

            stakingRewards.withdraw(toWithdraw);
        }
        super.beforeWithdraw(assets, shares);
    }

    /// -----------------------------------------------------------------------
    /// Staking functions
    /// -----------------------------------------------------------------------

    /// @notice Returns how much was earned during staking
    function reward() public view returns (address rewardsToken, uint256 earned) {
        return _calculateReward(stakingRewards);
    }

    /// @notice Allows owner to set or update a new staking contract. Will claim rewards from previous staking if available
    function updateStakingAddress(uint256 rewardIndex, address recipient) external onlyOwner {
        _stopStaking(recipient);

        IRewardsDistribution.DistributionData memory data = rewardsDistribution.distributions(rewardIndex);
        IStakingRewards stakingRewards_ = IStakingRewards(data.destination);
        if (stakingRewards_.stakingToken() != address(eToken)) revert StakeableEulerERC4626__InvalidRewardContract();

        stakingRewards = stakingRewards_;
        ERC20(address(eToken)).safeApprove(address(stakingRewards_), type(uint256).max);
    }

     /// @notice Allows owner to claim rewards and stop staking all together
    function stopStaking(address recipient) external onlyOwner {
        _stopStaking(recipient);
        stakingRewards = IStakingRewards(address(0));
    }

    /// @notice Allows owner to stake a certain amount of tokens
    function stake(uint256 amount) external onlyOwner {
        stakingRewards.stake(amount);
    }

    /// @notice Allows owner to unstake a certain amount of tokens
    function unstake(uint256 amount) external onlyOwner {
        stakingRewards.withdraw(amount);
    }

    /// @notice Allows owner to claim all staking rewards
    function claimReward(address recipient) public onlyOwner returns (address rewardsToken, uint256 earned) {
        (rewardsToken, earned) = reward();
        stakingRewards.getReward();
        _transferRewardToken(rewardsToken, earned, recipient);
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    function _getStakedBalance() internal view returns (uint256 eTokenStakedBalance) {
        IStakingRewards stakingRewards_ = stakingRewards;
        if (address(stakingRewards_) != address(0)) {
            return stakingRewards_.balanceOf(address(this));
        }
    } 

    function _calculateReward(IStakingRewards stakingRewards_) public view returns (address rewardToken, uint256 earned) {
        if (address(stakingRewards_) != address(0)) {
            rewardToken = stakingRewards_.rewardsToken();
            earned = stakingRewards_.earned(address(this));
        }
    }

    function _stopStaking(address recipient) internal {
        IStakingRewards stakingRewards_ = stakingRewards;
        if (address(stakingRewards_) != address(0)) {
            ERC20(address(eToken)).safeApprove(address(stakingRewards_), 0);
            (address rewardToken, uint256 earned) = _calculateReward(stakingRewards_);
            stakingRewards_.exit();
            _transferRewardToken(rewardToken, earned, recipient);
        }
    }

    function _transferRewardToken(address rewardToken, uint256 amount, address recipient) internal {
        if (amount > 0) {
            ERC20(rewardToken).safeTransfer(recipient, amount);
        }
    }
}