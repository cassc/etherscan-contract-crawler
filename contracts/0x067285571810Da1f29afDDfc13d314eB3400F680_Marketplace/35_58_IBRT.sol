//SPDX-License-Identifier: MIT
/**
 * @dev: @brougkr
 */
pragma solidity ^0.8.19;
interface IBRT { function ModifyRewardRates(uint[] calldata RewardIndexes, uint[] calldata RewardRates) external; }