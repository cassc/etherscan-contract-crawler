// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITreasuryBootstrap {
  function publicPurchase(uint256 amount, address recipient) external;

  event PublicPurchase(
    address indexed buyer,
    address indexed recipient,
    uint256 amountIn,
    uint256 amountOut
  );
}