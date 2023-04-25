// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IWombatBribeReader {

    function rewardInfo(uint256 index) external view returns (IERC20 rewardToken, uint96 tokenPerSec, uint128 accTokenPerShare, uint128 distributedAmount);

    function rewardLength() external view returns (uint256);
}