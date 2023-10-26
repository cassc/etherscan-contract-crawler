// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// ███╗   ██╗███████╗████████╗   ██╗      █████╗ ██████╗
// ████╗  ██║██╔════╝╚══██╔══╝   ██║     ██╔══██╗██╔══██╗
// ██╔██╗ ██║█████╗     ██║      ██║     ███████║██████╔╝
// ██║╚██╗██║██╔══╝     ██║      ██║     ██╔══██║██╔══██╗
// ██║ ╚████║██║        ██║      ███████╗██║  ██║██████╔╝
// ╚═╝  ╚═══╝╚═╝        ╚═╝      ╚══════╝╚═╝  ╚═╝╚═════╝
// NFT development start-finish, no up-front cost.
// Discord: https://discord.gg/kH7Gvnr2qp

interface NftLabModifiers {
  modifier is_active(bool sale_active) {
    require(sale_active, 'Sale is not yet active.');
    _;
  }

  modifier buy_limit(uint256 amt, uint256 max_buy) {
    require(amt <= max_buy, 'Amount of tokens exceeds limit.');
    _;
  }

  modifier token_limit(
    uint256 total,
    uint256 amt,
    uint256 max_tokens
  ) {
    require(total + amt <= max_tokens, 'Amount exceeds availability.');
    _;
  }

  modifier min_price(
    uint256 cost,
    uint256 amt,
    uint256 value
  ) {
    require(cost * amt <= value, 'ETH sent is below minimum.');
    _;
  }
}