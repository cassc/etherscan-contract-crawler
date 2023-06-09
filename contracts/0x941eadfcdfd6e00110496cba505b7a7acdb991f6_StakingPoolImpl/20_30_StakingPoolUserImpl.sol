// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/StakingPoolUser.sol";
import "./StakingPoolData.sol";

contract StakingPoolUserImpl is StakingPoolUser, StakingPoolData {
    IERC20 private immutable ctsi;
    uint256 public immutable lockTime;

    /// @dev Constructor
    /// @param _ctsi The contract that provides the staking pool's token
    /// @param _lockTime The user deposit lock period
    constructor(address _ctsi, uint256 _lockTime) {
        ctsi = IERC20(_ctsi);
        lockTime = _lockTime;
    }

    function deposit(uint256 _amount) external override whenNotPaused {
        // transfer tokens from caller to this contract
        // user must have approved the transfer a priori
        // tokens will be lying around, until actually staked by pool owner at a later time
        require(
            _amount > 0,
            "StakingPoolUserImpl: amount must be greater than 0"
        );

        // add tokens to user's balance
        UserBalance storage user = userBalance[msg.sender];
        user.balance += _amount;

        // reset deposit timestamp
        user.depositTimestamp = block.timestamp;

        // reserve the balance as required liquidity (don't stake to Staking)
        requiredLiquidity += _amount;

        require(
            ctsi.transferFrom(msg.sender, address(this), _amount),
            "StakingPoolUserImpl: failed to transfer tokens"
        );

        // emit event containing user and amount
        emit Deposit(msg.sender, _amount, block.timestamp + lockTime);
    }

    /// @notice Stake an amount of tokens, immediately earning pool shares in returns
    /// @param _amount amount of tokens to convert from user's balance
    function stake(uint256 _amount) external override whenNotPaused {
        // get user balance
        UserBalance storage user = userBalance[msg.sender];

        // transfer tokens from caller to this contract
        // user must have approved the transfer a priori
        // tokens will be lying around, until actually staked by pool owner at a later time
        require(
            _amount > 0,
            "StakingPoolUserImpl: amount must be greater than 0"
        );
        require(
            _amount <= user.balance,
            "StakingPoolUserImpl: not enough tokens available for staking"
        );

        // check if user can already stake or if it's too early
        require(
            block.timestamp >= user.depositTimestamp + lockTime,
            "StakingPoolUserImpl: not enough time has passed since last deposit"
        );

        // calculate amount of shares as of now
        uint256 _shares = amountToShares(_amount);

        // make sure he get at least one share (rounding errors)
        require(
            _shares > 0,
            "StakingPoolUserImpl: stake not enough to emit 1 share"
        );

        // allocate new shares to user, immediately
        user.shares += _shares;
        user.balance -= _amount;

        // increase total shares and amount (not changing share value)
        amount += _amount;
        shares += _shares;

        // remove from required liquidity, as it's moving to Staking
        requiredLiquidity -= _amount;

        // emit event containing user, amount, shares and unlock time
        emit Stake(msg.sender, _amount, _shares);
    }

    /// @notice allow for users to defined exactly how many shares they
    /// want to unstake. Estimated value is then emitted on Unstake event
    function unstake(uint256 _shares) external override {
        UserBalance storage user = userBalance[msg.sender];

        // check if shares is valid value
        require(_shares > 0, "StakingPoolUserImpl: invalid amount of shares");

        // check if user has enough shares to unstake
        require(
            user.shares >= _shares,
            "StakingPoolUserImpl: insufficient shares"
        );

        // reduce user number of shares
        user.shares -= _shares;

        // calculate amount of tokens from shares
        uint256 _amount = sharesToAmount(_shares);

        // reduce total shares and amount
        shares -= _shares;
        amount -= _amount;

        // add amount user can withdraw (if available)
        user.balance += _amount;

        // increase required liquidity
        requiredLiquidity += _amount;

        // emit event containing user, amount and shares
        emit Unstake(msg.sender, _amount, _shares);
    }

    /// @notice Transfer tokens back to calling user wallet
    /// @dev this will transfer all free tokens for the calling user
    function withdraw(uint256 _amount) external override {
        UserBalance storage user = userBalance[msg.sender];

        // check user released value
        require(
            user.balance > 0,
            "StakingPoolUserImpl: no balance to withdraw"
        );

        // clear user released value
        user.balance -= _amount; // if _amount >  user.balance this will revert

        // decrease required liquidity
        requiredLiquidity -= _amount; // if _amount >  requiredLiquidity this will revert

        // transfer token back to user
        require(
            ctsi.transfer(msg.sender, _amount),
            "StakingPoolUserImpl: failed to transfer tokens"
        );

        // emit event containing user and token amount
        emit Withdraw(msg.sender, _amount);
    }

    function getWithdrawBalance() external view override returns (uint256) {
        UserBalance storage user = userBalance[msg.sender];

        // get maximum amount user can withdraw (his balance)
        uint256 _amount = user.balance;

        // check contract balance
        uint256 balance = ctsi.balanceOf(address(this));

        // he can withdraw whatever is available at the contract, up to his balance
        return balance >= _amount ? _amount : balance;
    }
}