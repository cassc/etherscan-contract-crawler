// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
interface IRewarder {
    function onZeroxZeroReward(uint256 pid, address user, address recipient, uint256 zeroxzeroAmount, uint256 newLpAmount) external;
}