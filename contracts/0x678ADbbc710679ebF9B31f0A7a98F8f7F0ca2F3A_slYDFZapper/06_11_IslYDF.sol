// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/interfaces/IERC721.sol';

/**
 * @dev YDF Liquidity Staking
 */

interface IslYDF is IERC721 {
  function getAllUserOwned(address wallet)
    external
    view
    returns (uint256[] memory);

  function zapAndStakeETHAndYDF(uint256 amountYDF, uint256 lockOption)
    external
    payable;
}