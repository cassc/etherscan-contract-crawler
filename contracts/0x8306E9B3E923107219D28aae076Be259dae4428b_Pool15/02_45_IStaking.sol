// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "./../@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IStaking {

    function deposit(address tokenAddress, address wallet, uint256 amount) external;
    function withdraw(address tokenAddress, address wallet, uint256 amount) external;
    function balanceOf(address wallet, address tokenAddress) external view returns (uint);
    function getEpochId(uint timestamp) external view returns (uint); // get epoch id
    function getEpochUserBalance(address user, address token, uint128 epoch) external view returns(uint);
    function getEpochPoolSize(address token, uint128 epoch) external view returns (uint);
    function epoch1Start() external view returns (uint);
    function epochDuration() external view returns (uint);
    function getAndClearReward(address account, address tokenAddress) external returns (uint256);
}