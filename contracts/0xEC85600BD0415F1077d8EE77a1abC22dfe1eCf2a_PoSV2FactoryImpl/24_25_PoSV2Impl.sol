// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Proof of Stake V2
/// @author Stephen Chen

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "@cartesi/util/contracts/IWorkerAuthManager.sol";

import "./IPoSV2.sol";
import "./DifficultyManagerImpl.sol";
import "./EligibilityCalImpl.sol";
import "./HistoricalDataImpl.sol";
import "./RewardManagerV2Impl.sol";
import "../IStaking.sol";

contract PoSV2Impl is
    IPoSV2,
    Ownable,
    DifficultyManagerImpl,
    EligibilityCalImpl,
    HistoricalDataImpl
{
    uint32 public immutable version;
    IStaking public immutable staking;
    RewardManagerV2Impl public immutable rewardManager;
    IWorkerAuthManager public immutable workerAuth;
    address public immutable factory;

    bool public active;

    /// @param _ctsiAddress address of token instance being used
    /// @param _stakingAddress address of StakingInterface
    /// @param _workerAuthAddress address of worker manager contract
    /// @param _difficultyAdjustmentParameter how quickly the difficulty gets updated
    /// @param _targetInterval how often we want to elect a block producer
    /// @param _rewardValue reward that reward manager contract pays
    /// @param _rewardDelay number of blocks confirmation before a reward can be claimed
    /// @param _version protocol version of PoS
    constructor(
        address _ctsiAddress,
        address _stakingAddress,
        address _workerAuthAddress,
        // DifficultyManager constructor parameters
        uint128 _initialDifficulty,
        uint64 _minDifficulty,
        uint32 _difficultyAdjustmentParameter,
        uint32 _targetInterval,
        // RewardManager constructor parameters
        uint256 _rewardValue,
        uint32 _rewardDelay,
        uint32 _version
    )
        DifficultyManagerImpl(
            _initialDifficulty,
            _minDifficulty,
            _difficultyAdjustmentParameter,
            _targetInterval
        )
    {
        factory = msg.sender;
        version = _version;
        staking = IStaking(_stakingAddress);
        workerAuth = IWorkerAuthManager(_workerAuthAddress);

        rewardManager = new RewardManagerV2Impl(
            _ctsiAddress,
            address(this),
            _rewardValue,
            _rewardDelay
        );

        active = true;
        historicalCtx.latestCtx.ethBlockStamp = uint32(block.number);
    }

    // legacy methods from V1 chains for staking pool V1 compatibility
    /// @notice Produce a block in V1 chains
    /// @dev this function can only be called by a worker, user never calls it directly
    function produceBlock(uint256) external returns (bool) {
        require(version == 1, "protocol has to be V1");

        address user = _produceBlock();

        uint32 sidechainBlockNumber = historicalCtx
            .latestCtx
            .sidechainBlockCount;

        emit BlockProduced(user, msg.sender, sidechainBlockNumber, "");

        HistoricalDataImpl.updateLatest(user, sidechainBlockNumber + 1);
        rewardManager.reward(sidechainBlockNumber, user);

        return true;
    }

    /// @notice Produce a block in V2 chains
    /// @param _parent the parent block that current block appends to
    /// @param _data the data to store in the block
    /// @dev this function can only be called by a worker, user never calls it directly
    function produceBlock(
        uint32 _parent,
        bytes calldata _data
    ) external override returns (bool) {
        require(version == 2, "protocol has to be V2");

        address user = _produceBlock();

        emit BlockProduced(
            user,
            msg.sender,
            uint32(
                HistoricalDataImpl.recordBlock(
                    _parent,
                    user,
                    keccak256(abi.encodePacked(_data))
                )
            ),
            _data
        );

        return true;
    }

    /// @notice Check if address is allowed to produce block
    function canProduceBlock(
        address _user
    ) external view override returns (bool) {
        return
            EligibilityCalImpl.canProduceBlock(
                difficulty,
                historicalCtx.latestCtx.ethBlockStamp,
                _user,
                staking.getStakedBalance(_user)
            );
    }

    /// @notice Get when _user is allowed to produce a sidechain block
    /// @return uint256 mainchain block number when the user can produce a sidechain block
    function whenCanProduceBlock(
        address _user
    ) external view override returns (uint256) {
        return
            EligibilityCalImpl.whenCanProduceBlock(
                difficulty,
                historicalCtx.latestCtx.ethBlockStamp,
                _user,
                staking.getStakedBalance(_user)
            );
    }

    function getSelectionBlocksPassed() external view returns (uint256) {
        return
            EligibilityCalImpl.getSelectionBlocksPassed(
                historicalCtx.latestCtx.ethBlockStamp
            );
    }

    // legacy methods from V1 chains for staking pool V1 compatibility
    /// @notice Get reward manager address
    /// @return address of instance's RewardManager
    function getRewardManagerAddress(uint256) external view returns (address) {
        return address(rewardManager);
    }

    function terminate() external override onlyOwner {
        require(
            rewardManager.getCurrentReward() == 0,
            "RewardManager still holds funds"
        );

        active = false;
    }

    function _produceBlock() internal returns (address) {
        require(
            workerAuth.isAuthorized(msg.sender, factory) ||
                workerAuth.isAuthorized(msg.sender, address(this)),
            "msg.sender is not authorized"
        );

        address user = workerAuth.getOwner(msg.sender);
        uint32 ethBlockStamp = historicalCtx.latestCtx.ethBlockStamp;

        require(
            EligibilityCalImpl.canProduceBlock(
                difficulty,
                ethBlockStamp,
                user,
                staking.getStakedBalance(user)
            ),
            "User couldnt produce a block"
        );

        // difficulty
        DifficultyManagerImpl.adjustDifficulty(block.number - ethBlockStamp);

        return user;
    }
}