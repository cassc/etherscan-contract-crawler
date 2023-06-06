// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import './IStaderConfig.sol';

/// @title RewardsData
/// @notice This struct holds rewards merkleRoot and rewards split
struct RewardsData {
    /// @notice The block number when the rewards data was last updated
    uint256 reportingBlockNumber;
    /// @notice The index of merkle tree or rewards cycle
    uint256 index;
    /// @notice The merkle root hash
    bytes32 merkleRoot;
    /// @notice pool id of operators
    uint8 poolId;
    /// @notice operator ETH rewards for index cycle
    uint256 operatorETHRewards;
    /// @notice user ETH rewards for index cycle
    uint256 userETHRewards;
    /// @notice protocol ETH rewards for index cycle
    uint256 protocolETHRewards;
    /// @notice operator SD rewards for index cycle
    uint256 operatorSDRewards;
}

interface ISocializingPool {
    // errors
    error ETHTransferFailed(address recipient, uint256 amount);
    error SDTransferFailed();
    error RewardAlreadyHandled();
    error RewardAlreadyClaimed(address operator, uint256 cycle);
    error InsufficientETHRewards();
    error InsufficientSDRewards();
    error InvalidAmount();
    error InvalidProof(uint256 cycle, address operator);
    error InvalidCycleIndex();
    error FutureCycleIndex();

    // events
    event UpdatedStaderConfig(address indexed staderConfig);
    event ETHReceived(address indexed sender, uint256 amount);
    event UpdatedStaderValidatorRegistry(address indexed staderValidatorRegistry);
    event UpdatedStaderOperatorRegistry(address indexed staderOperatorRegistry);
    event OperatorRewardsClaimed(address indexed recipient, uint256 ethRewards, uint256 sdRewards);
    event OperatorRewardsUpdated(
        uint256 ethRewards,
        uint256 totalETHRewards,
        uint256 sdRewards,
        uint256 totalSDRewards
    );

    event UserETHRewardsTransferred(uint256 ethRewards);
    event ProtocolETHRewardsTransferred(uint256 ethRewards);

    // methods
    function handleRewards(RewardsData calldata _rewardsData) external;

    function claim(
        uint256[] calldata _index,
        uint256[] calldata _amountSD,
        uint256[] calldata _amountETH,
        bytes32[][] calldata _merkleProof
    ) external;

    // setters
    function updateStaderConfig(address _staderConfig) external;

    // getters
    function staderConfig() external view returns (IStaderConfig);

    function claimedRewards(address _user, uint256 _index) external view returns (bool);

    function totalOperatorETHRewardsRemaining() external view returns (uint256);

    function totalOperatorSDRewardsRemaining() external view returns (uint256);

    function initialBlock() external view returns (uint256);

    function verifyProof(
        uint256 _index,
        address _operator,
        uint256 _amountSD,
        uint256 _amountETH,
        bytes32[] calldata _merkleProof
    ) external view returns (bool);

    function getCurrentRewardsIndex() external view returns (uint256 index);

    function getRewardDetails()
        external
        view
        returns (
            uint256 currentIndex,
            uint256 currentStartBlock,
            uint256 currentEndBlock
        );

    function getRewardCycleDetails(uint256 _index) external view returns (uint256 _startBlock, uint256 _endBlock);
}