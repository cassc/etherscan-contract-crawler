// SPDX-License-Identifier: UNLICENCED
pragma solidity >=0.8.4;

library StarkwareSyncDtos {
  struct SwapArgs {
    uint256 tokenUserBuy;
    uint256 tokenUserSell;
    uint256 amountUserBuy;
    uint256 amountUserSell;
  }

  struct FundingArgs {
    address tokenA;
    address tokenB;
    // Quantized amounts
    uint256 tokenAAmount;
    uint256 tokenBAmount;
    uint256 lpAmount;
    bool isMint;
  }

  struct SwapAndFundingArgs {
    SwapArgs swapArgs;
    FundingArgs fundingArgs;
  }
}