// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title RewardManager V2
/// @author Stephen Chen

pragma solidity ^0.8.0;

import "@cartesi/util/contracts/Bitmask.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/utils/SafeERC20.sol";

import "./IHistoricalData.sol";
import "./IRewardManagerV2.sol";

contract RewardManagerV2Impl is IRewardManagerV2 {
    using Bitmask for mapping(uint256 => uint256);
    using SafeERC20 for IERC20;

    mapping(uint256 => uint256) internal rewarded;
    uint256 immutable rewardValue;
    uint32 immutable rewardDelay;
    IERC20 immutable ctsi;
    address public immutable pos;

    /// @notice Creates contract
    /// @param _ctsiAddress address of token instance being used
    /// @param _posAddress address of the sidechain
    /// @param _rewardValue reward that this contract pays
    /// @param _rewardDelay number of blocks confirmation before a reward can be claimed
    constructor(
        address _ctsiAddress,
        address _posAddress,
        uint256 _rewardValue,
        uint32 _rewardDelay
    ) {
        ctsi = IERC20(_ctsiAddress);
        //slither-disable-next-line  missing-zero-check
        pos = _posAddress;

        rewardValue = _rewardValue;
        rewardDelay = _rewardDelay;
    }

    /// @notice Rewards sidechain block for V1 chains
    /// @param _sidechainBlockNumber sidechain block number
    /// @param _address address to be rewarded
    function reward(uint32 _sidechainBlockNumber, address _address) external {
        require(msg.sender == pos, "Only the pos contract can call");

        uint256 cReward = currentReward();

        emit Rewarded(_sidechainBlockNumber, cReward);

        ctsi.safeTransfer(_address, cReward);
    }

    /// @notice Rewards sidechain blocks for V2 chains
    /// @param _sidechainBlockNumbers array of sidechain block numbers
    function reward(
        uint32[] calldata _sidechainBlockNumbers
    ) external override {
        for (uint256 i = 0; i < _sidechainBlockNumbers.length; ) {
            require(
                !rewarded.getBit(_sidechainBlockNumbers[i]),
                "The block has been rewarded"
            );

            //slither-disable-next-line  calls-loop
            (bool isValid, address producer) = IHistoricalData(pos)
                .isValidBlock(_sidechainBlockNumbers[i], rewardDelay);

            require(isValid, "Invalid block");

            uint256 cReward = currentReward();

            require(cReward > 0, "RewardManager has no funds");

            emit Rewarded(_sidechainBlockNumbers[i], cReward);

            ctsi.safeTransfer(producer, cReward);
            setRewarded(_sidechainBlockNumbers[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Get RewardManager's balance
    function getBalance() external view override returns (uint256) {
        return balance();
    }

    /// @notice Get current reward amount
    function getCurrentReward() external view override returns (uint256) {
        return currentReward();
    }

    /// @notice Check if a sidechain block reward is claimed
    function isRewarded(
        uint32 _sidechainBlockNumber
    ) external view override returns (bool) {
        return rewarded.getBit(_sidechainBlockNumber);
    }

    function setRewarded(uint32 _sidechainBlockNumber) private {
        rewarded.setBit(_sidechainBlockNumber, true);
    }

    function balance() private view returns (uint256) {
        //slither-disable-next-line  calls-loop
        return ctsi.balanceOf(address(this));
    }

    function currentReward() private view returns (uint256) {
        return rewardValue > balance() ? balance() : rewardValue;
    }
}