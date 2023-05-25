// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISaleable {
  function processSale(uint256 offeringId, address buyer, uint256 price) external;

  function getSellersFor(uint256 offeringId) external view returns (address[] memory sellers);

  event SellerAdded(address indexed seller, uint256 indexed offeringId);
  event SellerRemoved(address indexed seller, uint256 indexed offeringId);
}