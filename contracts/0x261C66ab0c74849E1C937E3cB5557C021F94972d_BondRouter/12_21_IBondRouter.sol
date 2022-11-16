// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBondRouter {
  struct Bond {
    address depository;
    uint256 id;
  }

  struct BondDetail {
    address depository;
    uint256 routerId;
    uint256 id;
    uint256 principal; // [wad]
    uint256 vestingPeriod; // [seconds]
    uint256 purchased; // [unix timestamp]
    uint256 lastRedeemed; // [unix timestamp]
  }

  enum BondType {
    TREASURY,
    STABILIZING
  }

  function purchaseTreasuryBond(
    address bond,
    uint256 amount,
    uint256 maxPrice,
    address recipient
  ) external returns (uint256 tokenId, uint256 bondId);

  function purchaseStabilizingBond(
    address bond,
    uint256 amount,
    uint256 maxPrice,
    uint256 minOutput,
    address recipient
  ) external returns (uint256 tokenId, uint256 bondId);

  function redeem(uint256 id, address recipient)
    external
    returns (uint256 payout, uint256 principal);

  function redeemAsStaked(uint256 id, address recipient)
    external
    returns (uint256 payout, uint256 principal);

  function redeemMultiple(uint256[] calldata id, address recipient)
    external
    returns (uint256 payout, uint256 principal);

  function redeemMultipleAsStaked(uint256[] calldata id, address recipient)
    external
    returns (uint256 payout, uint256 principal);

  function bondAt(address user, uint256 index) external view returns (uint256);

  function bondCount(address user) external view returns (uint256);

  function bondList(address user) external view returns (uint256[] memory);

  function bondDetailList(address owner)
    external
    view
    returns (BondDetail[] memory);

  function addBond(address _bondAddr, BondType _bondType) external;

  function removeBond(address _bondAddr) external;

  event AddedBond(address indexed _bondAddr, uint256 indexed _bondType);
  event RemovedBond(address indexed _bondAddr);
  event BondPurchased(
    uint256 indexed bondReceiptId,
    address indexed bond,
    address indexed recipient,
    uint256 bondId
  );
  event BondRedeemed(
    uint256 indexed bondReceiptId,
    address indexed bond,
    address indexed recipient,
    uint256 bondId,
    uint256 payout,
    uint256 principal
  );
}