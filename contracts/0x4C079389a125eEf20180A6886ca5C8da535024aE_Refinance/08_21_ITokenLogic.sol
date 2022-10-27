// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ICToken.sol';

interface ITokenLogic {
  // Enter Markets
  function enterMarkets(ICERC721 cToken) external returns(uint256[] memory);

  // Borrow ETH
  function borrowETH(address cToken, uint256 amount) external;

  // Claim NFTs
  function claimNFTs(
    address cToken,
    uint256[] calldata redeemTokenIndexes,
    address to
  ) external;

  // Claim cToken
  function claimCTokens(
    address cToken,
    uint256 amount,
    address to
  ) external;
}