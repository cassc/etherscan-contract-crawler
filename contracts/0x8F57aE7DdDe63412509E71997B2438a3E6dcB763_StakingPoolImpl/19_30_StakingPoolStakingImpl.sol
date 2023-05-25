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
import "@cartesi/pos/contracts/IStaking.sol";
import "./interfaces/StakingPoolStaking.sol";
import "./StakingPoolData.sol";

/// @notice This contract takes care of the interaction between the pool and the staking contract
/// It makes sure that there is enough liquidity in the pool to fullfil all unstake request from
/// users, by requesting to withdraw or unstake from Staking contract.
/// The remaining balance is staked.
contract StakingPoolStakingImpl is StakingPoolStaking, StakingPoolData {
    IERC20 private immutable ctsi;
    IStaking private immutable staking;

    constructor(address _ctsi, address _staking) {
        ctsi = IERC20(_ctsi);
        staking = IStaking(_staking);
    }

    function __StakingPoolStaking_init() internal {
        require(
            ctsi.approve(address(staking), type(uint256).max),
            "Failed to approve CTSI for staking contract"
        );
    }

    function rebalance() external override {
        // get amounts
        (uint256 _stake, uint256 _unstake, uint256 _withdraw) = amounts();

        if (_stake > 0) {
            // we can stake
            staking.stake(_stake);
        }

        if (_unstake > 0) {
            // we need to provide liquidity
            staking.unstake(_unstake);
        }

        if (_withdraw > 0) {
            // we need to provide liquidity
            staking.withdraw(_withdraw);
        }
    }

    function amounts()
        public
        view
        override
        returns (
            uint256 stake,
            uint256 unstake,
            uint256 withdraw
        )
    {
        // get this contract balance first
        uint256 balance = ctsi.balanceOf(address(this));

        if (balance > requiredLiquidity) {
            // we have spare tokens we can stake
            // check if there is anything already maturing, to avoid reset the maturation clock
            uint256 maturing = staking.getMaturingBalance(address(this));
            if (maturing == 0) {
                // nothing is maturing, we can stake the balance, preserving the liquidity
                stake = balance - requiredLiquidity;
            }
        } else if (requiredLiquidity > balance) {
            // we don't have enough tokens to provide liquidity
            uint256 missingLiquidity = requiredLiquidity - balance;

            // let's first check releasing balance
            uint256 releasing = staking.getReleasingBalance(address(this));
            if (releasing > 0) {
                // some is already releasing

                // let's check timestamp to see if we can withdrawn it
                uint256 timestamp = staking.getReleasingTimestamp(
                    address(this)
                );
                if (timestamp < block.timestamp) {
                    // there it is, let's grab it
                    withdraw = releasing;
                }

                // requiredLiquidity may be more than what is already releasing
                // but we won't unstake more to not reset the clock
            } else {
                // no unstake maturing, let's queue some
                unstake = missingLiquidity;
            }
        } else {
            // balance is exactly required liquidity, we can't move any tokens around
        }
    }
}