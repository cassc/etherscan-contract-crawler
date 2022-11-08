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

* Synthetix: QuoRewardPool.sol
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

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./Interfaces/IRewards.sol";
import "./Interfaces/IBaseRewardPool.sol";

contract QuoRewardPool is IRewards, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public wom;

    IERC20 public override stakingToken;
    address[] public rewardTokens;

    address public booster;
    address public womDepositor;
    address public qWomRewards;
    IERC20 public qWomToken;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    struct Reward {
        uint256 rewardPerTokenStored;
        uint256 queuedRewards;
    }

    struct UserReward {
        uint256 userRewardPerTokenPaid;
        uint256 rewards;
    }

    mapping(address => Reward) public rewards;
    mapping(address => bool) public isRewardToken;

    mapping(address => mapping(address => UserReward)) public userRewards;

    mapping(address => bool) public access;

    mapping(address => uint256) public userLastTime;

    mapping(address => uint256) public userAmountTime;

    function initialize() public initializer {
        __Ownable_init();
    }

    function setParams(
        address _stakingToken,
        address _wom,
        address _womDepositor,
        address _qWomRewards,
        address _qWomToken,
        address _booster
    ) external onlyOwner {
        require(
            address(stakingToken) == address(0),
            "params has already been set"
        );

        require(_stakingToken != address(0), "invalid _stakingToken!");
        require(_wom != address(0), "invalid _wom!");
        require(_womDepositor != address(0), "invalid _womDepositor!");
        require(_qWomRewards != address(0), "invalid _qWomRewards!");
        require(_qWomToken != address(0), "invalid _qWomToken!");
        require(_booster != address(0), "invalid _booster!");

        stakingToken = IERC20(_stakingToken);
        wom = _wom;
        booster = _booster;
        womDepositor = _womDepositor;
        qWomRewards = _qWomRewards;
        qWomToken = IERC20(_qWomToken);

        setAccess(_booster, true);
    }

    function addRewardToken(address _rewardToken) internal {
        require(_rewardToken != address(0), "invalid _rewardToken!");
        if (isRewardToken[_rewardToken]) {
            return;
        }
        rewardTokens.push(_rewardToken);
        isRewardToken[_rewardToken] = true;

        emit RewardTokenAdded(_rewardToken);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    modifier updateReward(address _account) {
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address rewardToken = rewardTokens[i];
            UserReward storage userReward = userRewards[_account][rewardToken];
            userReward.rewards = earned(_account, rewardToken);
            userReward.userRewardPerTokenPaid = rewards[rewardToken]
                .rewardPerTokenStored;
        }

        userAmountTime[_account] = getUserAmountTime(_account);
        userLastTime[_account] = now;

        _;
    }

    function getRewardTokens()
        external
        view
        override
        returns (address[] memory)
    {
        return rewardTokens;
    }

    function getRewardTokensLength() external view override returns (uint256) {
        return rewardTokens.length;
    }

    function earned(address _account, address _rewardToken)
        public
        view
        override
        returns (uint256)
    {
        Reward memory reward = rewards[_rewardToken];
        UserReward memory userReward = userRewards[_account][_rewardToken];
        return
            balanceOf(_account)
                .mul(
                    reward.rewardPerTokenStored.sub(
                        userReward.userRewardPerTokenPaid
                    )
                )
                .div(1e18)
                .add(userReward.rewards);
    }

    function getUserAmountTime(address _account)
        public
        view
        override
        returns (uint256)
    {
        uint256 lastTime = userLastTime[_account];
        if (lastTime == 0) {
            return 0;
        }
        uint256 userBalance = _balances[_account];
        if (userBalance == 0) {
            return userAmountTime[_account];
        }
        return userAmountTime[_account].add(now.sub(lastTime).mul(userBalance));
    }

    function stake(uint256 _amount) public override updateReward(msg.sender) {
        require(_amount > 0, "RewardPool : Cannot stake 0");

        //add supply
        _totalSupply = _totalSupply.add(_amount);
        //add to sender balance sheet
        _balances[msg.sender] = _balances[msg.sender].add(_amount);
        //take tokens from sender
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit Staked(msg.sender, _amount);
    }

    function stakeAll() external override {
        uint256 balance = stakingToken.balanceOf(msg.sender);
        stake(balance);
    }

    function stakeFor(address _for, uint256 _amount)
        external
        override
        updateReward(_for)
    {
        require(_for != address(0), "invalid _for!");
        require(_amount > 0, "RewardPool : Cannot stake 0");

        //add supply
        _totalSupply = _totalSupply.add(_amount);
        //add to _for's balance sheet
        _balances[_for] = _balances[_for].add(_amount);
        //take tokens from sender
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit Staked(_for, _amount);
    }

    function withdraw(uint256 _amount)
        public
        override
        updateReward(msg.sender)
    {
        require(_amount > 0, "RewardPool : Cannot withdraw 0");

        _totalSupply = _totalSupply.sub(_amount);
        _balances[msg.sender] = _balances[msg.sender].sub(_amount);
        stakingToken.safeTransfer(msg.sender, _amount);
        emit Withdrawn(msg.sender, _amount);

        _getReward(msg.sender, false);
    }

    function withdrawAll() external override {
        withdraw(_balances[msg.sender]);
    }

    function _getReward(address _account, bool _stake)
        internal
        updateReward(_account)
    {
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address rewardToken = rewardTokens[i];
            uint256 reward = earned(_account, rewardToken);
            if (reward > 0) {
                userRewards[_account][rewardToken].rewards = 0;
                if (rewardToken == address(qWomToken)) {
                    if (_stake) {
                        qWomToken.safeApprove(qWomRewards, 0);
                        qWomToken.safeApprove(qWomRewards, reward);
                        IBaseRewardPool(qWomRewards).stakeFor(_account, reward);
                    } else {
                        qWomToken.safeTransfer(_account, reward);
                    }
                } else {
                    // other token
                    IERC20(rewardToken).safeTransfer(_account, reward);
                }

                emit RewardPaid(_account, rewardToken, reward);
            }
        }
    }

    function getReward(bool _stake) external {
        _getReward(msg.sender, _stake);
    }

    function donate(address _rewardToken, uint256 _amount)
        external
        payable
        override
    {
        require(isRewardToken[_rewardToken], "invalid token");
        IERC20(_rewardToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        rewards[_rewardToken].queuedRewards = rewards[_rewardToken]
            .queuedRewards
            .add(_amount);
    }

    function queueNewRewards(address _rewardToken, uint256 _rewards)
        external
        payable
        override
    {
        require(access[msg.sender], "!authorized");

        addRewardToken(_rewardToken);

        IERC20(_rewardToken).safeTransferFrom(
            msg.sender,
            address(this),
            _rewards
        );

        Reward storage rewardInfo = rewards[_rewardToken];

        if (totalSupply() == 0) {
            rewardInfo.queuedRewards = rewardInfo.queuedRewards.add(_rewards);
            return;
        }

        _rewards = _rewards.add(rewardInfo.queuedRewards);
        rewardInfo.queuedRewards = 0;

        rewardInfo.rewardPerTokenStored = rewardInfo.rewardPerTokenStored.add(
            _rewards.mul(1e18).div(totalSupply())
        );
        emit RewardAdded(_rewardToken, _rewards);
    }

    function setAccess(address _address, bool _status)
        public
        override
        onlyOwner
    {
        require(_address != address(0), "invalid _address!");
        access[_address] = _status;
        emit AccessSet(_address, _status);
    }
}