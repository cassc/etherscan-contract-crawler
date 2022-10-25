// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IPhoenix is IERC20Metadata {
  function getPairs()
    external
    view
    returns (
      address pair,
      address[] memory pathBuy,
      address[] memory pathSell
    );

  function endRound() external;

  function addLiquidity(uint256 tokens) external payable;
}