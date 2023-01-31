// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ISliceProductPrice {
  function productPrice(
    uint256 slicerId,
    uint256 productId,
    address currency,
    uint256 quantity,
    address buyer,
    bytes memory data
  ) external view returns (uint256 ethPrice, uint256 currencyPrice);
}