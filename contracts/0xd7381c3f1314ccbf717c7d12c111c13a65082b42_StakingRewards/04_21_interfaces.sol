// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Deposit Token Interface for BAL Reward Pool
 */
interface IDepositToken is IERC20 {
    function mint(address, uint256) external;
    function burn(address, uint256) external;
}

/**
 * @dev BAL Reward Pool
 */
interface IBALRewardPool {    
    function earned(address) external view returns (uint256);
    function stakeFor(address, uint256) external;
    function withdrawFor(address, uint256) external;
    function getReward(address) external;
    function getRewardRate() external view returns (uint256);
    function processIdleRewards() external;
    function queueNewRewards(uint256) external;    
}

/**
 * @dev Asset Data
 */
struct AssetData {
    uint128 emissionPerSecond;
    uint128 lastUpdateTimestamp; 
    uint256 index;
    mapping(address => uint256) users;
}