// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import '../libs/Stakes.sol';

interface IStaking {
    /**
     * @dev Possible states an allocation can be
     * States:
     * - Null = Staker == address(0)
     * - Pending = not Null && tokens > 0 && escrowAddress status == Pending
     * - Active = Pending && escrowAddress status == Launched
     * - Closed = Active && closedAt != 0
     * - Completed = Closed && closedAt && escrowAddress status == Complete
     */
    enum AllocationState {
        Null,
        Pending,
        Active,
        Closed,
        Completed
    }

    /**
     * @dev Possible sort fields
     * Fields:
     * - None = Do not sort
     * - Stake = Sort by stake amount
     */
    enum SortField {
        None,
        Stake
    }

    /**
     * @dev Allocate HMT tokens for the purpose of serving queries of a subgraph deployment
     * An allocation is created in the allocate() function and consumed in claim()
     */
    struct Allocation {
        address escrowAddress;
        address staker;
        uint256 tokens; // Tokens allocated to a escrowAddress
        uint256 createdAt; // Time when allocation was created
        uint256 closedAt; // Time when allocation was closed
    }

    function rewardPool() external view returns (address);

    function setMinimumStake(uint256 _minimumStake) external;

    function setLockPeriod(uint32 _lockPeriod) external;

    function setRewardPool(address _rewardPool) external;

    function isAllocation(address _escrowAddress) external view returns (bool);

    function hasStake(address _indexer) external view returns (bool);

    function hasAvailableStake(address _indexer) external view returns (bool);

    function getAllocation(
        address _escrowAddress
    ) external view returns (Allocation memory);

    function getAllocationState(
        address _escrowAddress
    ) external view returns (AllocationState);

    function getStakedTokens(address _staker) external view returns (uint256);

    function getStaker(
        address _staker
    ) external view returns (Stakes.Staker memory);

    function stake(uint256 _tokens) external;

    function unstake(uint256 _tokens) external;

    function withdraw() external;

    function slash(
        address _slasher,
        address _staker,
        address _escrowAddress,
        uint256 _tokens
    ) external;

    function allocate(address escrowAddress, uint256 _tokens) external;

    function closeAllocation(address _escrowAddress) external;

    function getListOfStakers()
        external
        view
        returns (address[] memory, Stakes.Staker[] memory);
}