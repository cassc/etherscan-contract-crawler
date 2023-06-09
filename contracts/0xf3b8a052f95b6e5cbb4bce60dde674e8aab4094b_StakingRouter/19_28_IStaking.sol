// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

interface IStaking {

    event RewardSharesIncrement(uint256 amount, uint256 totalSupply, address indexed sender);
    event CalculatorUpdate(address indexed prevValue, address indexed newValue, address indexed sender);
    event Stake(
        bytes32 indexed stakeId,
        address indexed recipient,
        StakeDetails details,
        address sender
    );
    event Unstake(
        bytes32 indexed stakeId,
        UnstakeReceipt receipt,
        address indexed to,
        address indexed sender
    );
    event Skim(
        bytes32 indexed stakeId,
        uint256 amount,
        address indexed recipient,
        address indexed sender
    );

    struct UnstakeReceipt {
        uint128 amount;
        uint128 principal;
        uint128 rewards;
        uint128 tokensReceived;
        uint128 unstakePenalty;
        uint32 unstakePenaltyPercent;
    }

    struct StakeDetails {
        uint128 principal;
        uint128 totalSupply;

        uint256 rewardSharesStart;

        uint32 rewardMultiplier;
        uint32 stakeDuration;
        uint32 lockDuration;
        uint48 createdAt;
        uint48 expiresAt;
    }

    function STAKING_TOKEN() external view returns (address);

    function calculator() external view returns (address);

    function totalRewards() external view returns (uint256);
    function totalRewardShares() external view returns (uint256);
    function totalValue() external view returns (uint256);
    function totalMultiplied() external view returns (uint256);
    function totalStakesCreated() external view returns (uint256);

    function balanceOf(address account, bytes32 stakeId) external view returns (uint256);
    function totalBalance(bytes32 stakeId, uint256 amount) external view returns (uint256);
    function rewardBalance(bytes32 stakeId, uint256 amount) external view returns (uint256);
    function unstakePenalty(bytes32 stakeId) external view returns (uint256);
    function principalBalance(bytes32 stakeId, uint256 amount) external view returns (uint256);
    function predictUnstake(bytes32 stakeId, uint256 amount) external view returns (UnstakeReceipt memory);
    function stakeDetails(bytes32 stakeId) external view returns (StakeDetails memory);
    function updateCalculator(address newCalculator) external;

    function skim(bytes32 stakeId, address recipient) external returns (bool);
    function stake(
        address account,
        uint256 maxTokens,
        uint32 stakeDuration,
        uint32 lockDuration
    ) external returns (bytes32 stakeId, StakeDetails memory details);
    function unstake(
        bytes32 stakeId,
        address recipient
    ) external returns (UnstakeReceipt memory receipt);
}