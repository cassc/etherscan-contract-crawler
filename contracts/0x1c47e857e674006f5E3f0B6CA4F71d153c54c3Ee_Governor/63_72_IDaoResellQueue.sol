// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IDaoResellQueue {
  //################
  //#### STRUCTS ####

  struct SaleItem {
    address owner;
    uint32 splitId;
    uint128 amount;
    uint128 claimThreshold;
  }

  struct PurchaseItem {
    address owner;
    uint256 split;
    uint256 amount;
  }

  struct CumulativeTotals {
    uint128 cumulativeSold;
    uint128 cumulativeDeleted;
  }

  //################
  //#### EVENTS ####

  event SaleItemQueued(address causeToken, address owner, uint256 saleItem);

  event SaleItemDequeued(address causeToken, address owner, uint128 amount);

  //################
  //#### ERRORS ####

  error CannotBeZeroAddress();

  //###################
  //#### FUNCTIONS ####
  function enqueue(address _causeToken, uint128 _amount) external;

  function dequeue(address _causeToken, uint128 _saleId) external;

  function purchaseAvailable(address _causeToken, uint256 _amount)
    external
    returns (PurchaseItem[] memory purchaseItems);

  // function setMinimumSaleAmount(address _causeToken, uint128 _amount) external;

  function forceDequeue(address _causeToken, uint128[] calldata _listingIds)
    external;

  function setSaleSplit(address _causeToken, uint256 _splitAmount) external;

  //################################
  //#### AUTO-GENERATED GETTERS ####

  function causeSplitId(address _causeToken)
    external
    view
    returns (uint32 splitId);

  function split(uint32 _splitId) external view returns (uint256 split);

  function saleItems(address _causeToken, uint256 _saleItemId)
    external
    view
    returns (
      address owner,
      uint32 splitId,
      uint128 amount,
      uint128 claimThreshold
    );

  function cumulativeTotals(address _causeToken)
    external
    view
    returns (uint128 totalSold, uint128 totalDeleted);

  function clearingHouse() external view returns (address clearingHouse);

  function saleItemCounter() external view returns (uint256 id);

  function validateProceedsClaim(address _causeToken, uint256 _saleItemId)
    external;
}