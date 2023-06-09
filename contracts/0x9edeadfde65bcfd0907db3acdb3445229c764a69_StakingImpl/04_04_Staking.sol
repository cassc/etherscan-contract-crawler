// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Interface staking contract
pragma solidity ^0.7.0;

interface Staking {

    /// @notice Returns total amount of tokens counted as stake
    /// @param _userAddress user to retrieve staked balance from
    /// @return finalized staked of _userAddress
    function getStakedBalance(
        address _userAddress) external view returns (uint256);

    /// @notice Returns the timestamp when next deposit can be finalized
    /// @return timestamp of when finalizeStakes() is callable
    function getMaturingTimestamp(address _userAddress) external view returns (uint256);

    /// @notice Returns the timestamp when next withdraw can be finalized
    /// @return timestamp of when finalizeWithdraw() is callable
    function getReleasingTimestamp(address _userAddress) external view returns (uint256);


    /// @notice Returns the balance waiting/ready to be matured
    /// @return amount that will get staked after finalization
    function getMaturingBalance(address _userAddress) external view  returns (uint256);

    /// @notice Returns the balance waiting/ready to be released
    /// @return amount that will get withdrew after finalization
    function getReleasingBalance(address _userAddress) external view  returns (uint256);


    /// @notice Deposit CTSI to be staked. The money will turn into staked
    ///         balance after timeToStake days
    /// @param _amount The amount of tokens that are gonna be deposited.
    function stake(uint256 _amount) external;

    /// @notice Remove tokens from staked balance. The money can
    ///         be released after timeToRelease seconds, if the
    ///         function withdraw is called.
    /// @param _amount The amount of tokens that are gonna be unstaked.
    function unstake(uint256 _amount) external;

    /// @notice Transfer tokens to user's wallet.
    /// @param _amount The amount of tokens that are gonna be transferred.
    function withdraw(uint256 _amount) external;

    // events
    /// @notice CTSI tokens were deposited, they count as stake after _maturationDate
    /// @param user address of msg.sender
    /// @param amount amount deposited for staking
    /// @param maturationDate date when the stake can be finalized
    event Stake(
        address indexed user,
        uint256 amount,
        uint256 maturationDate
    );

    /// @notice Unstake tokens, moving them to releasing structure
    /// @param user address of msg.sender
    /// @param amount amount of tokens to be released
    /// @param maturationDate date when the tokens can be withdrew
    event Unstake(
        address indexed user,
        uint256 amount,
        uint256 maturationDate
    );

    /// @notice Withdraw process was finalized
    /// @param user address of msg.sender
    /// @param amount amount of tokens withdrawn
    event Withdraw(
        address indexed user,
        uint256 amount
    );
}