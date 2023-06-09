// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Cartesi Staking
/// @author Felipe Argento
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Staking.sol";

contract StakingImpl is Staking {
    using SafeMath for uint256;
    IERC20 private ctsi;

    uint256 timeToStake; // time it takes for deposited tokens to become staked.
    uint256 timeToRelease; // time it takes from witdraw signal to tokens to be unlocked.

    mapping(address => uint256) staked; // amount of money being staked.
    mapping(address => MaturationStruct) maturing; // deposits waiting to be staked.
    mapping(address => MaturationStruct) releasing; // money waiting for withdraw.

    struct MaturationStruct {
        uint256 amount;
        uint256 timestamp;
    }

    /// @notice constructor
    /// @param _ctsiAddress address of compatible ERC20
    /// @param _timeToStake time it takes for deposited tokens to become staked.
    /// @param _timeToRelease time it takes from unstake to tokens being unlocked.
    constructor(
        address _ctsiAddress,
        uint256 _timeToStake,
        uint256 _timeToRelease
    ) {
        ctsi = IERC20(_ctsiAddress);
        timeToStake = _timeToStake;
        timeToRelease = _timeToRelease;
    }

    function stake(uint256 _amount) public override {
        require(_amount > 0, "amount cant be zero");

        // pointers to releasing/maturing structs
        MaturationStruct storage r = releasing[msg.sender];
        MaturationStruct storage m = maturing[msg.sender];

        // check if there are mature coins to be staked
        if (m.timestamp.add(timeToStake) <= block.timestamp) {
            staked[msg.sender] = staked[msg.sender].add(m.amount);
            m.amount = 0;
        }

        // first move tokens from releasing pool to maturing
        // then transfer from wallet
        if (r.amount >= _amount) {
            r.amount = (r.amount).sub(_amount);
        } else {
            // transfer stake to contract
            // from: msg.sender
            // to: this contract
            // value: _amount - releasing[msg.sender].amount
            ctsi.transferFrom(msg.sender, address(this), _amount.sub(r.amount));
            r.amount = 0;

        }

        m.amount = (m.amount).add(_amount);
        m.timestamp = block.timestamp;

        emit Stake(
            msg.sender,
            m.amount,
            block.timestamp.add(timeToStake)
        );
    }

    function unstake(uint256 _amount) public override {
        require(_amount > 0, "amount cant be zero");

        // pointers to releasing/maturing structs
        MaturationStruct storage r = releasing[msg.sender];
        MaturationStruct storage m = maturing[msg.sender];

        if (m.amount >= _amount) {
            m.amount = (m.amount).sub(_amount);
        } else {
            // safemath.sub guarantees that _amount <= m.amount + staked amount
            staked[msg.sender] = staked[msg.sender].sub(_amount.sub(m.amount));
            m.amount = 0;
        }
        // update releasing amount
        r.amount = (r.amount).add(_amount);
        r.timestamp = block.timestamp;

        emit Unstake(
            msg.sender,
            r.amount,
            block.timestamp.add(timeToRelease)
        );
    }

    function withdraw(uint256 _amount) public override {
        // pointer to releasing struct
        MaturationStruct storage r = releasing[msg.sender];

        require(_amount > 0, "amount cant be zero");
        require(
            r.timestamp.add(timeToRelease) <= block.timestamp,
            "tokens are not yet ready to be released"
        );

        r.amount = (r.amount).sub(_amount, "not enough tokens waiting to be released;");

        // withdraw tokens
        // from: this contract
        // to: msg.sender
        // value: bet total withdraw value on toWithdraw
        ctsi.transfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    // getters
    function getMaturingTimestamp(
        address _userAddress
    )
    public
    view override
    returns (uint256)
    {
        return maturing[_userAddress].timestamp.add(timeToStake);
    }

    function getMaturingBalance(
        address _userAddress
    )
    public
    view override
    returns (uint256)
    {
        MaturationStruct storage m = maturing[_userAddress];

        if (m.timestamp.add(timeToStake) <= block.timestamp) {
            return 0;
        }

        return m.amount;
    }

    function getReleasingBalance(
        address _userAddress
    )
    public
    view override
    returns (uint256)
    {
        return releasing[_userAddress].amount;
    }

    function getReleasingTimestamp(
        address _userAddress
    )
    public
    view override
    returns (uint256)
    {
        return releasing[_userAddress].timestamp.add(timeToRelease);
    }

    function getStakedBalance(address _userAddress)
    public
    view override
    returns (uint256)
    {
        MaturationStruct storage m = maturing[_userAddress];

        // if there are mature deposits, treat them as staked
        if (m.timestamp.add(timeToStake) <= block.timestamp) {
            return staked[_userAddress].add(m.amount);
        }

        return staked[_userAddress];
    }
}