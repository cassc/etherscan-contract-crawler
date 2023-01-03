// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

error SaleEnded();
error SaleOpen();
error QuantityBelowMinimum();
error InvalidEtherValue();
error NotSupported();
error ExceedsAllocation();

contract SmashversePresale is Ownable, Pausable, PaymentSplitter {
  uint256 public immutable unitPrice;
  uint256 public immutable maxQuantity;

  bool public ended;
  mapping(address => uint256) public quantityPurchased;

  event Sale(address indexed buyer, uint256 amount, uint256 quantity);
  event PresaleEnded();
  event PresaleOpened();

  constructor(
    address[] memory payees_,
    uint256[] memory shares_,
    uint256 unitPrice_,
    uint256 maxQuantity_
  ) PaymentSplitter(payees_, shares_) {
    unitPrice = unitPrice_;
    maxQuantity = maxQuantity_;
  }

  modifier whenSaleRunning() {
    if (hasSaleEnded()) revert SaleEnded();
    _;
  }

  function hasSaleEnded() public view returns (bool) {
    return ended;
  }

  function isSaleRunning() public view returns (bool) {
    return !hasSaleEnded();
  }

  function openSale() external onlyOwner {
    if (!hasSaleEnded()) revert SaleOpen();
    ended = false;
    emit PresaleOpened();
  }

  function endSale() external onlyOwner {
    if (hasSaleEnded()) revert SaleEnded();
    ended = true;
    emit PresaleEnded();
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function buy(uint256 quantity_)
    external
    payable
    whenSaleRunning
    whenNotPaused
  {
    if (quantity_ == 0) revert QuantityBelowMinimum();

    uint256 expectedAmount = quantity_ * unitPrice;

    if (msg.value != expectedAmount) revert InvalidEtherValue();

    // check that the amount being purchased won't push the address over their allocation
    if (quantityPurchased[msg.sender] + quantity_ > maxQuantity)
      revert ExceedsAllocation();

    quantityPurchased[msg.sender] += quantity_;

    emit Sale(msg.sender, msg.value, quantity_);
  }

  // reverts if receiving any eth directly
  receive() external payable override {
    revert NotSupported();
  }

  // fallback function
  fallback() external payable {
    revert NotSupported();
  }
}