// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/interfaces/IERC721AQueryable.sol";

interface IUnicornMultiverse is IERC721AQueryable {
  error InvalidEtherValue();
  error MaxPerWalletOverflow();
  error TotalSupplyOverflow();
  error InvalidProof();

  struct MintRules {
    uint64 totalSupply;
    uint64 maxPerWallet;
    uint64 whitelistMaxPerWallet;
    uint64 freePerWallet;
    uint64 whitelistFreePerWallet;
    uint256 price;
    uint256 whitelistPrice;
  }
}