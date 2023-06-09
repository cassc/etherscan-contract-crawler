// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/interfaces/IERC721AQueryable.sol";

interface IIceCream is IERC721AQueryable {
  error InvalidEtherValue();
  error MaxPerWalletOverflow();
  error TotalSupplyOverflow();
  error InvalidProof();

  struct MintRules {
    uint64 totalSupply;
    uint64 maxPerWallet;
    uint64 whitelistExtraPerWallet;
    uint64 freePerWallet;
    uint256 price;
    uint256 whitelistPrice;
  }
}