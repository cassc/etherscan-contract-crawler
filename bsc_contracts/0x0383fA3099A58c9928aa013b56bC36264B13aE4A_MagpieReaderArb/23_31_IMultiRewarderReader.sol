// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IMultiRewarderReader {
    

    function rewardTokens() external view returns (IERC20[] memory tokens);
    function rewardLength() external view returns (uint256);
    //rewardToken address, tokenPerSec uint96, accTokenPerShare uint128, distributedAmount uint128
    function rewardInfo(uint256 id) external view returns ( address,  uint96,  uint128,  uint128);
}