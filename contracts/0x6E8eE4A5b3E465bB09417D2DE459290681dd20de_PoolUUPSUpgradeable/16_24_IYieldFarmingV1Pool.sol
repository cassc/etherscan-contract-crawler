// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IYieldFarmingV1Pool {
    struct PoolConfig {
        address[] poolTokenAddresses;
        address rewardTokenAddress;
        address stakingAddress;
        address rewardsEscrowAddress;
        uint256 totalDistributedAmount;
        uint128 numberOfEpochs;
        uint128 epochsDelayedFromStaking;
    }

    struct TokenDetails {
        address addr;
        uint8 decimals;
    }

    function initialize(PoolConfig memory cfg, address roleAdmin) external;

    function rewardToken() external view returns (IERC20Upgradeable);

    function epoch1Start() external view returns (uint256);

    function epochDuration() external view returns (uint256);

    function numberOfEpochs() external view returns (uint128);

    function totalDistributedAmount() external view returns (uint256);

    function getPoolTokens() external view returns (address[] memory tokens);

    function getCurrentEpoch() external view returns (uint128);

    function getEpochPoolSize(uint128 epochId) external view returns (uint256);

    function getEpochPoolSizeByToken(address token, uint128 epochId) external view returns (uint256);

    function getEpochUserBalance(address userAddress, uint128 epochId) external view returns (uint256);

    function getEpochUserBalanceByToken(address userAddress, address token, uint128 epochId) external view returns (uint256);

    function getClaimableAmount(address account) external view returns (uint256);
}