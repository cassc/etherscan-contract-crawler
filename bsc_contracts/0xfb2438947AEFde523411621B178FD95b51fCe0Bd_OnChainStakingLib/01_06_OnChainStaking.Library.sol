// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;

import "../common/SafeAmount.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library OnChainStakingLib {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Staked(address indexed token, address indexed staker_, uint256 requestedAmount_, uint256 stakedAmount_);

    event PaidOut(address indexed token, address indexed rewardToken, address indexed staker_, uint256 amount_, uint256 reward_);

    struct OnChainStakingState {
        uint256 stakedTotal;
        uint256 stakingCap;
        uint256 stakedBalance;
        mapping(address => uint256) _stakes;
    }

    struct OnChainStakingRewardState {
        uint256 rewardsTotal;
        uint256 rewardBalance;
        uint256 earlyWithdrawReward;
    }

    function VERSION() external pure returns (uint) {
        return 1002;
    }

    function tryStake(address payer, address staker, uint256 amount,
        uint256 stakingStarts,
        uint256 stakingEnds,
        uint256 stakingCap,
        address tokenAddress,
        OnChainStakingState storage state
    )
    public
    _after(stakingStarts)
    _before(stakingEnds)
    _positive(amount)
    returns (uint256) {
        // check the remaining amount to be staked
        // For pay per transfer tokens we limit the cap on incoming tokens for simplicity. This might
        // mean that cap may not necessary fill completely which is ok.
        uint256 remaining = amount;
        {
            uint256 stakedBalance = state.stakedBalance;
            if (stakingCap > 0 && remaining > (stakingCap.sub(stakedBalance))) {
                remaining = stakingCap.sub(stakedBalance);
            }
        }
        // These requires are not necessary, because it will never happen, but won't hurt to double check
        // this is because stakedTotal and stakedBalance are only modified in this method during the staking period
        // require((remaining + stakedTotal) <= stakingCap, "OnChainStaking: this will increase staking amount pass the cap");
        // Update remaining in case actual amount paid was different.
        remaining = _payMe(payer, remaining, tokenAddress);
        emit Staked(tokenAddress, staker, amount, remaining);

        // Transfer is completed
        return remaining;
    }

    function stake(address payer, address staker, uint256 amount,
        uint256 stakingStarts,
        uint256 stakingEnds,
        uint256 stakingCap,
        address tokenAddress,
        OnChainStakingState storage state
    )
    external
    returns (bool) {
        uint256 remaining = tryStake(payer, staker, amount,
            stakingStarts, stakingEnds, stakingCap, tokenAddress, state);

        // Transfer is completed
        state.stakedBalance = state.stakedBalance.add(remaining);
        state.stakedTotal = state.stakedTotal.add(remaining);
        state._stakes[staker] = state._stakes[staker].add(remaining);
        return true;
    }

    function addReward(
        uint256 rewardAmount,
        uint256 withdrawableAmount,
        address rewardTokenAddress,
        OnChainStakingRewardState storage state
    )
    external
    returns (bool) {
        require(rewardAmount > 0, "OnChainStaking: reward must be positive");
        require(withdrawableAmount >= 0, "OnChainStaking: withdrawable amount cannot be negative");
        require(withdrawableAmount <= rewardAmount, "OnChainStaking: withdrawable amount must be less than or equal to the reward amount");
        address from = msg.sender;
        rewardAmount = _payMe(from, rewardAmount, rewardTokenAddress);
        state.rewardsTotal = state.rewardsTotal.add(rewardAmount);
        state.rewardBalance = state.rewardBalance.add(rewardAmount);
        state.earlyWithdrawReward = state.earlyWithdrawReward.add(withdrawableAmount);
        return true;
    }

    function addMarginalReward(
        address rewardTokenAddress,
        address tokenAddress,
        address me,
        uint256 stakedBalance,
        OnChainStakingRewardState storage state)
    external
    returns (bool) {
        uint256 amount = IERC20(rewardTokenAddress).balanceOf(me).sub(state.rewardsTotal);
        if (rewardTokenAddress == tokenAddress) {
            amount = amount.sub(stakedBalance);
        }
        if (amount == 0) {
            return true;
            // No reward to add. Its ok. No need to fail callers.
        }
        state.rewardsTotal = state.rewardsTotal.add(amount);
        state.rewardBalance = state.rewardBalance.add(amount);
        return true;
    }

    function tryWithdraw(
        address from,
        address tokenAddress,
        address rewardTokenAddress,
        uint256 amount,
        uint256 withdrawStarts,
        uint256 withdrawEnds,
        uint256 stakingEnds,
        OnChainStakingState storage state,
        OnChainStakingRewardState storage rewardState
    )
    public
    _after(withdrawStarts)
    _positive(amount)
    _realAddress(msg.sender)
    returns (uint256) {
        require(amount <= state._stakes[from], "OnChainStaking: not enough balance");
        if (block.timestamp < withdrawEnds) {
            return _withdrawEarly(tokenAddress, rewardTokenAddress, from, amount, withdrawEnds,
                stakingEnds, state, rewardState);
        } else {
            return _withdrawAfterClose(tokenAddress, rewardTokenAddress, from, amount, state, rewardState);
        }
    }

    function withdraw(
        address from,
        address tokenAddress,
        address rewardTokenAddress,
        uint256 amount,
        uint256 withdrawStarts,
        uint256 withdrawEnds,
        uint256 stakingEnds,
        OnChainStakingState storage state,
        OnChainStakingRewardState storage rewardState
    )
    public
    returns (bool) {
        uint256 wdAmount = tryWithdraw(from, tokenAddress, rewardTokenAddress, amount, withdrawStarts,
            withdrawEnds, stakingEnds, state, rewardState);
        state.stakedBalance = state.stakedBalance.sub(wdAmount);
        state._stakes[from] = state._stakes[from].sub(wdAmount);
        return true;
    }

    function _withdrawEarly(
        address tokenAddress,
        address rewardTokenAddress,
        address from,
        uint256 amount,
        uint256 withdrawEnds,
        uint256 stakingEnds,
        OnChainStakingState storage state,
        OnChainStakingRewardState storage rewardState
    )
    private
    _realAddress(from)
    returns (uint256) {
        // This is the formula to calculate reward:
        // r = (earlyWithdrawReward / stakedTotal) * (block.timestamp - stakingEnds) / (withdrawEnds - stakingEnds)
        // w = (1+r) * a
        uint256 denom = (withdrawEnds.sub(stakingEnds)).mul(state.stakedTotal);
        uint256 reward = (
        ((block.timestamp.sub(stakingEnds)).mul(rewardState.earlyWithdrawReward)).mul(amount)
        ).div(denom);
        rewardState.rewardBalance = rewardState.rewardBalance.sub(reward);
        bool principalPaid = _payDirect(from, amount, tokenAddress);
        bool rewardPaid = _payDirect(from, reward, rewardTokenAddress);
        require(principalPaid && rewardPaid, "OnChainStaking: error paying");
        emit PaidOut(tokenAddress, rewardTokenAddress, from, amount, reward);
        return amount;
    }

    function _withdrawAfterClose(
        address tokenAddress,
        address rewardTokenAddress,
        address from,
        uint256 amount,
        OnChainStakingState storage state,
        OnChainStakingRewardState storage rewardState
    ) private
    _realAddress(from)
    returns (uint256) {
        uint256 rewBal = rewardState.rewardBalance;
        uint256 reward = (rewBal.mul(amount)).div(state.stakedBalance);
        rewardState.rewardBalance = rewBal.sub(reward);
        bool principalPaid = _payDirect(from, amount, tokenAddress);
        bool rewardPaid = _payDirect(from, reward, rewardTokenAddress);
        require(principalPaid && rewardPaid, "OnChainStaking: error paying");
        emit PaidOut(tokenAddress, rewardTokenAddress, from, amount, reward);
        return amount;
    }

    function _payMe(address payer, uint256 amount, address token)
    internal
    returns (uint256) {
        return _payTo(payer, address(this), amount, token);
    }

    function _payTo(address allower, address receiver, uint256 amount, address token)
    internal
    returns (uint256) {
        // Request to transfer amount from the contract to receiver.
        // contract does not own the funds, so the allower must have added allowance to the contract
        // Allower is the original owner.
        return SafeAmount.safeTransferFrom(token, allower, receiver, amount);
    }

    function _payDirect(address to, uint256 amount, address token)
    private
    returns (bool) {
        if (amount == 0) {
            return true;
        }
        IERC20(token).safeTransfer(to, amount);
        return true;
    }

    modifier _realAddress(address addr) {
        require(addr != address(0), "OnChainStaking: zero address");
        _;
    }

    modifier _positive(uint256 amount) {
        require(amount != 0, "OnChainStaking: negative amount");
        _;
    }

    modifier _after(uint eventTime) {
        require(block.timestamp >= eventTime, "OnChainStaking: bad timing for the request");
        _;
    }

    modifier _before(uint eventTime) {
        require(block.timestamp < eventTime, "OnChainStaking: bad timing for the request");
        _;
    }
}