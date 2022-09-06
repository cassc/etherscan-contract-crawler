// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract IHPMarketplaceMint {
  function marketplaceMint(
    address to,
    address creatorRoyaltyAddress,
    uint96 feeNumerator,
    string memory uri,
    string memory trackId
  ) external virtual returns(uint256);

  function canMarketplaceMint() public pure returns(bool) {
    return true;
  }
}