// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/IDaoResellQueue.sol";

contract DaoResellQueue is IDaoResellQueue {
  mapping(address => uint32) public override causeSplitId;
  mapping(uint32 => uint256) public override split;
  mapping(address => mapping(uint256 => SaleItem)) public override saleItems;
  mapping(address => CumulativeTotals) public override cumulativeTotals;
  uint256 public override saleItemCounter;

  address public override clearingHouse;

  constructor(address _clearingHouse) {
    _checkZeroAddress(_clearingHouse);
    clearingHouse = _clearingHouse;
  }

  function _checkZeroAddress(address _address) internal pure {
    if (_address == address(0)) {
      revert CannotBeZeroAddress();
    }
  }

  function _incremenetSaleItemCounter()
    internal
    returns (uint256 incrementedCount)
  {}

  function enqueue(address _causeToken, uint128 _amount) external override {}

  function dequeue(address _causeToken, uint128 _saleId) external override {}

  function purchaseAvailable(address _causeToken, uint256 _amount)
    external
    override
    returns (PurchaseItem[] memory purchaseItems)
  {}

  function forceDequeue(address _causeToken, uint128[] calldata _listingIds)
    external
    override
  {}

  function setSaleSplit(address _causeToken, uint256 _splitAmount)
    external
    override
  {}

  function validateProceedsClaim(address _causeToken, uint256 _saleItemId)
    external
    override
  {}
}