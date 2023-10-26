// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITradingTokenV1 {
  event SwapTokensForETH(
    uint256 amountIn,
    address[] path
  );
  function launch() external payable;
  function getTokenData() external view returns (
    string memory name_, 
    string memory symbol_, 
    uint8 decimals_,
    uint256 totalSupply_,
    uint256 totalBalance_,
    uint256 launchedAt,
    address owner_,
    address dexPair
  );
}