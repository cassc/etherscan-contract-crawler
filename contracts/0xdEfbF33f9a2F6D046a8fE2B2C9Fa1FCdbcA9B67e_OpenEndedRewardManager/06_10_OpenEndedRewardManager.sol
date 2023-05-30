pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./IFestakeRewardManager.sol";
import "./IFestakeWithdrawer.sol";
import "./Festaked.sol";

/**
 * Allows stake, unstake, and add reward at any time.
 * stake and reward token can be different.
 */
contract OpenEndedRewardManager is 
        Festaked,
        IFestakeRewardManager, IFestakeWithdrawer {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public override rewardToken;
    uint256 public override rewardsTotal;
    uint256 public fakeRewardsTotal;
    mapping (address=>uint256) fakeRewards;

    constructor(
        string memory name_,
        address tokenAddress_,
        address rewardTokenAddress_,
        uint stakingStarts_,
        uint stakingEnds_,
        uint withdrawStarts_,
        uint withdrawEnds_,
        uint256 stakingCap_) Festaked(name_, tokenAddress_, stakingStarts_, stakingEnds_,
            withdrawStarts_, withdrawEnds_, stakingCap_) public {
            rewardToken = IERC20(rewardTokenAddress_);
    }

    /**
     * First send the rewards to this contract, then call this method.
     * Designed to be called by smart contracts.
     */
    function addMarginalReward()
    external override returns (bool) {
        return _addMarginalReward();
    }

    function _addMarginalReward()
    internal virtual returns (bool) {
        address me = address(this);
        IERC20 _rewardToken = rewardToken;
        uint256 amount = _rewardToken.balanceOf(me).sub(rewardsTotal);
        if (address(_rewardToken) == tokenAddress) {
            amount = amount.sub(stakedBalance);
        }
        if (amount == 0) {
            return true; // No reward to add. Its ok. No need to fail callers.
        }
        rewardsTotal = rewardsTotal.add(amount);
        fakeRewardsTotal = fakeRewardsTotal.add(amount);
        return true;
    }

    function addReward(uint256 rewardAmount)
    external override returns (bool) {
        require(rewardAmount != 0, "OERM: rewardAmount is zero");
        rewardToken.safeTransferFrom(msg.sender, address(this), rewardAmount);
        _addMarginalReward();
    }

    function fakeRewardOf(address staker) external view returns (uint256) {
        return fakeRewards[staker];
    }

    function rewardOf(address staker)
    external override virtual view returns (uint256) {
        uint256 stake = Festaked._stakes[staker];
        return _calcRewardOf(staker, stakedBalance, stake);
    }

    function _calcRewardOf(address staker, uint256 totalStaked_, uint256 stake)
    internal view returns (uint256) {
        if (stake == 0) {
            return 0;
        }
        uint256 fr = fakeRewards[staker];
        uint256 rew = _calcReward(totalStaked_, fakeRewardsTotal, stake);
        return rew > fr ? rew.sub(fr) : 0; // Ignoring the overflow problem
    }

    function withdrawRewards() external override virtual returns (uint256) {
        require(msg.sender != address(0), "OERM: Bad address");
        return _withdrawRewards(msg.sender);
    }

    /**
     * First withdraw all rewards, than withdarw it all, then stake back the remaining.
     */
    function withdraw(uint256 amount) external override virtual returns (bool) {
        address _staker = msg.sender;
        return _withdraw(_staker, amount);
    }

    function _withdraw(address _staker, uint256 amount)
    internal virtual returns (bool) {
        if (amount == 0) {
            return true;
        }
        uint256 actualPay = _withdrawOnlyUpdateState(_staker, amount);
        IERC20(tokenAddress).safeTransfer(_staker, amount);
        if (actualPay != 0) {
            rewardToken.safeTransfer(_staker, actualPay);
        }
        emit PaidOut(tokenAddress, address(rewardToken), _staker, amount, actualPay);
        return true;
    }

    function _withdrawOnlyUpdateState(address _staker, uint256 amount)
    internal virtual returns (uint256) {
        uint256 userStake = _stakes[_staker];
        require(amount <= userStake, "OERM: Not enough balance");
        uint256 userFake = fakeRewards[_staker];
        uint256 fakeTotal = fakeRewardsTotal;
        uint256 _stakedBalance = stakedBalance;
        uint256 actualPay = _calcWithdrawRewards(userStake, userFake, _stakedBalance, fakeTotal);

        uint256 fakeRewAmount = _calculateFakeRewardAmount(amount, fakeTotal, _stakedBalance);

        fakeRewardsTotal = fakeRewardsTotal.sub(fakeRewAmount);
        fakeRewards[_staker] = userFake.add(actualPay).sub(fakeRewAmount);
        rewardsTotal = rewardsTotal.sub(actualPay);
        stakedBalance = _stakedBalance.sub(amount);
        _stakes[_staker] = userStake.sub(amount);
        return actualPay;
    }

    function _stake(address payer, address staker, uint256 amount)
    virtual
    override
    internal
    _after(stakingStarts)
    _before(withdrawEnds)
    _positive(amount)
    _realAddress(payer)
    _realAddress(staker)
    returns (bool) {
        return _stakeNoPreAction(payer, staker, amount);
    }

    function _stakeNoPreAction(address payer, address staker, uint256 amount)
    internal
    returns (bool) {
        uint256 remaining = amount;
        uint256 _stakingCap = stakingCap;
        uint256 _stakedBalance = stakedBalance;
        // check the remaining amount to be staked
        // For pay per transfer tokens we limit the cap on incoming tokens for simplicity. This might
        // mean that cap may not necessary fill completely which is ok.
        if (_stakingCap != 0 && remaining > (_stakingCap.sub(_stakedBalance))) {
            remaining = _stakingCap.sub(_stakedBalance);
        }
        // These requires are not necessary, because it will never happen, but won't hurt to double check
        // this is because stakedTotal and stakedBalance are only modified in this method during the staking period
        require(remaining != 0, "OERM: Staking cap is filled");
        require(stakingCap == 0 || remaining.add(stakedBalance) <= stakingCap, "OERM: this will increase staking amount pass the cap");
        // Update remaining in case actual amount paid was different.
        remaining = _payMe(payer, remaining, tokenAddress);
        require(_stakeUpdateStateOnly(staker, remaining), "OERM: Error staking");
        // To ensure total is only updated here. Not when simulating the stake.
        stakedTotal = stakedTotal.add(remaining);
        emit Staked(tokenAddress, staker, amount, remaining);
    }

    function _stakeUpdateStateOnly(address staker, uint256 amount)
    internal returns (bool) {
        uint256 _stakedBalance = stakedBalance;
        uint256 _fakeTotal = fakeRewardsTotal;
        bool isNotNew = _stakedBalance != 0;
        uint256 curRew = isNotNew ?
            _calculateFakeRewardAmount(amount, _fakeTotal, _stakedBalance) :
            _fakeTotal;

        _stakedBalance = _stakedBalance.add(amount);
        _stakes[staker] = _stakes[staker].add(amount);
        fakeRewards[staker] = fakeRewards[staker].add(curRew);

        stakedBalance = _stakedBalance;
        if (isNotNew) {
            fakeRewardsTotal = _fakeTotal.add(curRew);
        }
        return true;
    }

    function _calculateFakeRewardAmount(
        uint256 amount, uint256 baseFakeTotal, uint256 baseStakeTotal
    ) internal pure returns (uint256) {
        return amount.mul(baseFakeTotal).div(baseStakeTotal);
    }

    function _withdrawRewards(address _staker) internal returns (uint256) {
        uint256 userStake = _stakes[_staker];
        uint256 _stakedBalance = stakedBalance;
        uint256 totalFake = fakeRewardsTotal;
        uint256 userFake = fakeRewards[_staker];
        uint256 actualPay = _calcWithdrawRewards(userStake, userFake, _stakedBalance, totalFake);
        rewardsTotal = rewardsTotal.sub(actualPay);
        fakeRewards[_staker] = fakeRewards[_staker].add(actualPay);
        if (actualPay != 0) {
            rewardToken.safeTransfer(_staker, actualPay);
        }
        emit PaidOut(tokenAddress, address(rewardToken), _staker, 0, actualPay);
        return actualPay;
    }

    function _calcWithdrawRewards(
        uint256 _stakedAmount,
        uint256 _userFakeRewards,
        uint256 _totalStaked,
        uint256 _totalFakeRewards)
    internal pure returns (uint256) {
        uint256 toPay = _calcReward(_totalStaked, _totalFakeRewards, _stakedAmount);
        return toPay > _userFakeRewards ? toPay.sub(_userFakeRewards) : 0; // Ignore rounding issue
    }

    function _calcReward(uint256 total, uint256 fakeTotal, uint256 staked)
    internal pure returns (uint256) {
        return fakeTotal.mul(staked).div(total);
    }
}