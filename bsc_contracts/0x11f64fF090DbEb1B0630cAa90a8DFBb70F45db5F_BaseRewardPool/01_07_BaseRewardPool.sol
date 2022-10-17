// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
/**
 *Submitted for verification at Etherscan.io on 2020-07-17
 */

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: BaseRewardPool.sol
*
* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

import "./interfaces/Interfaces.sol";
import "./interfaces/MathUtil.sol";
import "@openzeppelin/contracts-0.6/math/SafeMath.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.6/utils/Address.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";

/**
 * @title   BaseRewardPool
 * @author  Synthetix -> ConvexFinance -> WombexFinance
 * @notice  Unipool rewards contract that is re-deployed from rFactory for each staking pool.
 * @dev     Changes made here by ConvexFinance are to do with the delayed reward allocation. Curve is queued for
 *          rewards and the distribution only begins once the new rewards are sufficiently large, or the epoch
 *          has ended. Also some changes from WombexFinance.
 */
contract BaseRewardPool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable stakingToken;
    IERC20 public immutable boosterRewardToken;
    uint256 public constant DURATION = 7 days;
    uint256 public constant NEW_REWARD_RATIO = 830;
    uint256 public constant MAX_TOKENS = 100;

    address public operator;
    uint256 public pid;

    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;

    struct RewardState {
        address token;
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 queuedRewards;
        uint256 currentRewards;
        uint256 historicalRewards;
        bool paused;
    }

    mapping(address => RewardState) public tokenRewards;
    address[] public allRewardTokens;

    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) public rewards;

    event UpdateOperatorData(address indexed sender, address indexed operator, uint256 indexed pid);
    event SetRewardTokenPaused(address indexed sender, address indexed token, bool indexed paused);
    event RewardAdded(address indexed token, uint256 currentRewards, uint256 newRewards);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed token, address indexed user, uint256 reward);
    event Donate(address indexed token, uint256 amount);

    /**
     * @dev This is called directly from RewardFactory
     * @param pid_                  Effectively the pool identifier - used in the Booster
     * @param stakingToken_         Pool LP token
     * @param boosterRewardToken_   Reward token for call booster on queueNewRewards
     * @param operator_             Booster
     */
    constructor(
        uint256 pid_,
        address stakingToken_,
        address boosterRewardToken_,
        address operator_
    ) public {
        pid = pid_;
        stakingToken = IERC20(stakingToken_);
        boosterRewardToken = IERC20(boosterRewardToken_);
        operator = operator_;
    }

    function updateOperatorData(address operator_, uint256 pid_) external {
        require(msg.sender == operator, "!authorized");
        operator = operator_;
        pid = pid_;

        emit UpdateOperatorData(msg.sender, operator_, pid_);
    }

    function setRewardTokenPaused(address token_, bool paused_) external {
        require(msg.sender == operator, "!authorized");

        tokenRewards[token_].paused = paused_;

        emit SetRewardTokenPaused(msg.sender, token_, paused_);
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    modifier updateReward(address account) {
        uint256 len = allRewardTokens.length;
        for (uint256 i = 0; i < len; i++) {
            RewardState storage rState = tokenRewards[allRewardTokens[i]];

            rState.rewardPerTokenStored = _rewardPerToken(rState);
            rState.lastUpdateTime = _lastTimeRewardApplicable(rState);
            if (account != address(0)) {
                rewards[rState.token][account] = _earned(rState, account);
                userRewardPerTokenPaid[rState.token][account] = rState.rewardPerTokenStored;
            }
        }
        _;
    }

    function lastTimeRewardApplicable(address _token) public view returns (uint256) {
        return _lastTimeRewardApplicable(tokenRewards[_token]);
    }

    function rewardPerToken(address _token) public view returns (uint256) {
        return _rewardPerToken(tokenRewards[_token]);
    }

    function earned(address _token, address _account) public view returns (uint256) {
        return _earned(tokenRewards[_token], _account);
    }

    function claimableRewards(address _account) external view returns (address[] memory tokens, uint256[] memory amounts) {
        tokens = allRewardTokens;
        amounts = new uint256[](allRewardTokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            amounts[i] = _earned(tokenRewards[tokens[i]], _account);
        }
    }

    function stake(uint256 _amount)
        public
        returns(bool)
    {
        _processStake(_amount, msg.sender);

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);

        return true;
    }

    function stakeAll() external returns(bool){
        uint256 balance = stakingToken.balanceOf(msg.sender);
        stake(balance);
        return true;
    }

    function stakeFor(address _for, uint256 _amount)
        public
        returns(bool)
    {
        _processStake(_amount, _for);

        //take away from sender
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(_for, _amount);

        return true;
    }

    /**
     * @dev Generic internal staking function that basically does 3 things: update rewards based
     *      on previous balance, trigger also on any child contracts, then update balances.
     * @param _amount    Units to add to the users balance
     * @param _receiver  Address of user who will receive the stake
     */
    function _processStake(uint256 _amount, address _receiver) internal updateReward(_receiver) {
        require(_amount > 0, 'RewardPool : Cannot stake 0');

        _totalSupply = _totalSupply.add(_amount);
        _balances[_receiver] = _balances[_receiver].add(_amount);
    }

    function withdraw(uint256 amount, bool claim)
        public
        updateReward(msg.sender)
        returns(bool)
    {
        require(amount > 0, 'RewardPool : Cannot withdraw 0');

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);

        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);

        if(claim){
            getReward(msg.sender, false);
        }

        return true;
    }

    function withdrawAll(bool claim) external{
        withdraw(_balances[msg.sender],claim);
    }

    function withdrawAndUnwrap(uint256 amount, bool claim) public returns(bool){
        _withdrawAndUnwrapTo(amount, msg.sender, msg.sender);
        //get rewards too
        if(claim){
            getReward(msg.sender, false);
        }
        return true;
    }

    function _withdrawAndUnwrapTo(uint256 amount, address from, address receiver) internal updateReward(from) returns(bool){
        _totalSupply = _totalSupply.sub(amount);
        _balances[from] = _balances[from].sub(amount);

        //tell operator to withdraw from here directly to user
        IDeposit(operator).withdrawTo(pid,amount,receiver);
        emit Withdrawn(from, amount);

        return true;
    }

    function withdrawAllAndUnwrap(bool claim) external{
        withdrawAndUnwrap(_balances[msg.sender],claim);
    }

    /**
     * @dev Gives a staker their rewards, with the option of claiming extra rewards
     * @param _account     Account for which to claim
     * @param _lockCvx     Get the child rewards too?
     */
    function getReward(address _account, bool _lockCvx) public updateReward(_account) returns(bool){
        uint256 len = allRewardTokens.length;
        for (uint256 i = 0; i < len; i++) {
            RewardState storage rState = tokenRewards[allRewardTokens[i]];
            if (rState.paused) {
                continue;
            }

            uint256 reward = _earned(rState, _account);
            if (reward > 0) {
                rewards[rState.token][_account] = 0;
                IERC20(rState.token).safeTransfer(_account, reward);
                if (rState.token == address(boosterRewardToken)) {
                    IDeposit(operator).rewardClaimed(pid, _account, reward, _lockCvx);
                }
                emit RewardPaid(rState.token, _account, reward);
            }
        }
        return true;
    }

    /**
     * @dev Called by a staker to get their allocated rewards
     */
    function getReward() external returns(bool){
        getReward(msg.sender, false);
        return true;
    }

    /**
     * @dev Donate some extra rewards to this contract
     */
    function donate(address _token, uint256 _amount) external returns(bool){
        uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        _amount = IERC20(_token).balanceOf(address(this)).sub(balanceBefore);

        tokenRewards[_token].queuedRewards = tokenRewards[_token].queuedRewards.add(_amount);

        emit Donate(_token, _amount);
    }

    /**
     * @dev Processes queued rewards in isolation, providing the period has finished.
     *      This allows a cheaper way to trigger rewards on low value pools.
     */
    function processIdleRewards() external {
        uint256 len = allRewardTokens.length;
        for (uint256 i = 0; i < len; i++) {
            RewardState storage rState = tokenRewards[allRewardTokens[i]];
            if (block.timestamp >= rState.periodFinish && rState.queuedRewards > 0) {
                _notifyRewardAmount(rState, rState.queuedRewards);
                rState.queuedRewards = 0;
            }
        }
    }

    /**
     * @dev Called by the booster to allocate new Crv/WOM rewards to this pool
     *      Curve is queued for rewards and the distribution only begins once the new rewards are sufficiently
     *      large, or the epoch has ended.
     */
    function queueNewRewards(address _token, uint256 _rewards) external returns(bool){
        require(msg.sender == operator, "!authorized");

        uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _rewards);

        _rewards = IERC20(_token).balanceOf(address(this)).sub(balanceBefore);

        RewardState storage rState = tokenRewards[_token];
        if (rState.lastUpdateTime == 0) {
            rState.token = _token;
            allRewardTokens.push(_token);
            require(allRewardTokens.length <= MAX_TOKENS, "!`max_tokens`");
        }
        _rewards = _rewards.add(rState.queuedRewards);

        if (block.timestamp >= rState.periodFinish) {
            _notifyRewardAmount(rState, _rewards);
            rState.queuedRewards = 0;
            return true;
        }

        //et = now - (finish-duration)
        uint256 elapsedTime = block.timestamp.sub(rState.periodFinish.sub(DURATION));
        //current at now: rewardRate * elapsedTime
        uint256 currentAtNow = rState.rewardRate * elapsedTime;
        uint256 queuedRatio = currentAtNow.mul(1000).div(_rewards);

        //uint256 queuedRatio = currentRewards.mul(1000).div(_rewards);
        if(queuedRatio < NEW_REWARD_RATIO){
            _notifyRewardAmount(rState, _rewards);
            rState.queuedRewards = 0;
        }else{
            rState.queuedRewards = _rewards;
        }
        return true;
    }

    function _notifyRewardAmount(RewardState storage _rState, uint256 _reward)
        internal
        updateReward(address(0))
    {
        _rState.historicalRewards = _rState.historicalRewards.add(_reward);
        if (block.timestamp >= _rState.periodFinish) {
            _rState.rewardRate = _reward.div(DURATION);
        } else {
            uint256 remaining = _rState.periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(_rState.rewardRate);
            _reward = _reward.add(leftover);
            _rState.rewardRate = _reward.div(DURATION);
        }
        _rState.currentRewards = _reward;
        _rState.lastUpdateTime = block.timestamp;
        _rState.periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(_rState.token, _rState.currentRewards, _reward);
    }

    function _lastTimeRewardApplicable(RewardState storage _rState) internal view returns (uint256) {
        return MathUtil.min(block.timestamp, _rState.periodFinish);
    }

    function _earned(RewardState storage _rState, address account) internal view returns (uint256) {
        return
        balanceOf(account)
            .mul(_rewardPerToken(_rState).sub(userRewardPerTokenPaid[_rState.token][account]))
            .div(1e18)
            .add(rewards[_rState.token][account]);
    }

    function _rewardPerToken(RewardState storage _rState) internal view returns (uint256) {
        if (totalSupply() == 0) {
            return _rState.rewardPerTokenStored;
        }
        return
            _rState.rewardPerTokenStored.add(
                _lastTimeRewardApplicable(_rState)
                .sub(_rState.lastUpdateTime)
                .mul(_rState.rewardRate)
                .mul(1e18)
                .div(totalSupply())
            );
    }

    function rewardTokensLen() external view returns (uint256) {
        return allRewardTokens.length;
    }

    function rewardTokensList() external view returns (address[] memory) {
        return allRewardTokens;
    }
}