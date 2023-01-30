//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IPriceFeed {
  // --- Events ---
  event LastGoodPriceUpdated(uint256 _lastGoodPrice);

  // --- Function ---
  function fetchPrice() external returns (uint256);

  function getDecimalPercision() external view returns (uint256);
}