// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Proof of Stake
/// @author Felipe Argento

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@cartesi/util/contracts/InstantiatorImpl.sol";
import "@cartesi/util/contracts/Decorated.sol";
import "@cartesi/util/contracts/WorkerAuthManager.sol";

import "./Staking.sol";
import "./BlockSelector.sol";
import "./RewardManager.sol";

contract PoS is Ownable, InstantiatorImpl, Decorated {
    using SafeMath for uint256;

    struct PoSCtx {
        uint256 blockSelectorIndex;
        BlockSelector blockSelector;
        Staking staking;
        RewardManager rewardManager;
        WorkerAuthManager workerAuth;
    }

    mapping(uint256 => PoSCtx) internal instance;

    event Rewarded(
        uint256 indexed index,
        address indexed worker,
        address indexed user,
        uint256 reward
    );

    event NewChain (
        uint256 indexed index,
        address stakingAddress,
        address blockSelectorAddress,
        address workerAuthAddress,
        uint256 minimumDifficulty,
        uint256 initialDifficulty,
        uint32 difficultyAdjustmentParameter,
        uint32 targetInterval,
        address ctsiAddress,
        uint256 maxReward,
        uint256 minReward,
        uint256 distNumerator,
        uint256 distDenominator
    );
    /// @notice Instantiates a Proof of Stake
    /// @param _stakingAddress address of StakingInterface
    /// @param _blockSelectorAddress address of blockSelector contract
    /// @param _workerAuthAddress address of worker manager contract
    /// @param _difficultyAdjustmentParameter how quickly the difficulty gets updated
    /// according to the difference between time passed and desired draw time interval.
    /// @param _targetInterval how often we want to elect a block producer
    /// @param _ctsiAddress address of token instance being used
    /// @param _maxReward maximum reward that this contract pays
    /// @param _minReward minimum reward that this contract pays
    /// @param _distNumerator multiplier factor to define reward amount
    /// @param _distDenominator dividing factor to define reward amount
    function instantiate(
        address _stakingAddress,
        address _blockSelectorAddress,
        address _workerAuthAddress,
        uint256 _minimumDifficulty,
        uint256 _initialDifficulty,
        uint32 _difficultyAdjustmentParameter,
        uint32 _targetInterval,

        // RewardManager constructor parameters
        address _ctsiAddress,
        uint256 _maxReward,
        uint256 _minReward,
        uint256 _distNumerator,
        uint256 _distDenominator
    ) public onlyOwner() returns (uint256) {

        // index is incremented at the beggining to stop reentrancy possibilities
        // TODO: study using ReentrancyGuard contract
        currentIndex++;

        instance[currentIndex - 1].staking = Staking(_stakingAddress);
        instance[currentIndex - 1].blockSelector = BlockSelector(
            _blockSelectorAddress
        );

        instance[currentIndex - 1].workerAuth = WorkerAuthManager(
            _workerAuthAddress
        );

        active[currentIndex - 1] = true;

        // there is no reentrancy because the bytecode is included in this contract
        instance[currentIndex - 1].rewardManager = new RewardManager(
            address(this),
            _ctsiAddress,
            _maxReward,
            _minReward,
            _distNumerator,
            _distDenominator
        );

        instance[currentIndex - 1].blockSelectorIndex = instance[currentIndex -
            1]
            .blockSelector
            .instantiate(
            _minimumDifficulty,
            _initialDifficulty,
            _difficultyAdjustmentParameter,
            _targetInterval,
            address(this)
        );

        emit NewChain (
            currentIndex - 1,
            _stakingAddress,
            _blockSelectorAddress,
            _workerAuthAddress,
            _minimumDifficulty,
            _initialDifficulty,
            _difficultyAdjustmentParameter,
            _targetInterval,
            _ctsiAddress,
            _maxReward,
            _minReward,
            _distNumerator,
            _distDenominator
        );

        return currentIndex - 1;
    }

    /// @notice Produce a block
    /// @param _index the index of the instance of pos you want to interact with
    /// @dev this function can only be called by a worker, user never calls it directly
    function produceBlock(uint256 _index) public returns (bool) {
        PoSCtx storage pos = instance[_index];

        require(
            pos.workerAuth.isAuthorized(msg.sender, address(this)),
            "msg.sender is not authorized to make this call"
        );

        address user = pos.workerAuth.getOwner(msg.sender);

        require(
            pos.blockSelector.produceBlock(
                pos.blockSelectorIndex,
                user,
                pos.staking.getStakedBalance(user)
            ),
            "User couldnt produce a block successfully"
        );

        uint256 currentReward = pos.rewardManager.getCurrentReward();

        pos.rewardManager.reward(user, currentReward);
        emit Rewarded(
            _index,
            msg.sender,
            user,
            currentReward
        );

        return true;
    }

    /// @notice Get reward manager address
    /// @param _index index of instance
    /// @return address of instance's RewardManager
    function getRewardManagerAddress(uint256 _index)
        public
        view
        returns (address)
    {
        return address(instance[_index].rewardManager);
    }

    /// @notice Get block selector address
    /// @param _index index of instance
    /// @return address of instance's block selector
    function getBlockSelectorAddress(uint256 _index)
        public
        view
        returns (address)
    {
        return address(instance[_index].blockSelector);
    }

    /// @notice Get block selector index
    /// @param _index index of instance
    /// @return index of instance's block selector
    function getBlockSelectorIndex(uint256 _index)
        public
        view
        returns (uint256)
    {
        return instance[_index].blockSelectorIndex;
    }

    /// @notice Get staking address
    /// @param _index index of instance
    /// @return address of instance's staking contract
    function getStakingAddress(uint256 _index)
        public
        view
        returns (address)
    {
        return address(instance[_index].staking);
    }

    /// @notice Get state of a particular instance
    /// @param _index index of instance
    /// @param _user address of user
    /// @return bool if user is eligible to produce next block
    /// @return address of user that was chosen to build the block
    /// @return current reward paid by the network for that block
    function getState(uint256 _index, address _user)
        public
        view
        returns (
            bool,
            address,
            uint256
        )
    {
        PoSCtx storage pos = instance[_index];
        return (
            pos.blockSelector.canProduceBlock(
                pos.blockSelectorIndex,
                _user,
                pos.staking.getStakedBalance(_user)
            ),
            _user,
            pos.rewardManager.getCurrentReward()
        );
    }

    function isConcerned(uint256 _index, address _user)
        public
        override
        view
        returns (bool)
    {
        PoSCtx storage pos = instance[_index];
        return pos.staking.getStakedBalance(_user) > 0;
    }

    function getSubInstances(uint256 _index, address)
        public
        override
        view
        returns (address[] memory _addresses, uint256[] memory _indices)
    {
        PoSCtx storage pos = instance[_index];

        address[] memory a;
        uint256[] memory i;

        a = new address[](1);
        i = new uint256[](1);

        a[0] = address(pos.blockSelector);
        i[0] = pos.blockSelectorIndex;
        return (a, i);
    }

    function terminate(uint256 _index) public onlyOwner() {
        PoSCtx storage pos = instance[_index];
        require(
            pos.rewardManager.getCurrentReward() == 0,
            "RewardManager still holds funds"
        );
        deactivate(_index);
    }
}