//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ILlamaZoo {
  function getStakedTokens(address account) external view returns (uint256[] memory llamas, uint256 pixletCanvas, uint256 llamaDraws, uint128 silverBoosts, uint128 goldBoosts);
}