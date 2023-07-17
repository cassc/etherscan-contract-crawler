// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract WhoAnonPaymentCollector is Ownable, Pausable {
  address public beneficiary;
  uint256 public shippingCost = 0.02 ether;

  constructor(address beneficiary_) {
    beneficiary = beneficiary_;
  }

  event PaymentCollected(
    address indexed payer,
    uint256 indexed tokenId,
    uint256 value,
    uint256 shippingCost,
    uint256 tokenQuantity
  );

  event ShippingCostUpdated(uint256 oldShippingCost, uint256 newShippingCost);

  error IncorrectPayment();
  error InvalidTokenQuantity();
  error TransferFailed();
  error NotAuthorized();

  /**
   * @dev pause - pause functions that are designated pausable (onlyOwner).
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @dev unpause - pause functions that are designated pausable (onlyOwner).
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @dev setShippingCost - set the shipping cost (onlyOwner).
   *
   * @param shippingCost_ The new shipping cost in wei
   */
  function setShippingCost(uint256 shippingCost_) external onlyOwner {
    uint256 oldShippingCost = shippingCost;
    shippingCost = shippingCost_;

    emit ShippingCostUpdated(oldShippingCost, shippingCost_);
  }

  /**
   * @dev collectPayment - collect a shipping payment.
   *
   * @param tokenId_ The tokenId that the payment is being collected for
   * @param tokenQuantity_ The number of tokens for this payment
   */
  function collectPayment(
    uint256 tokenId_,
    uint256 tokenQuantity_
  ) external payable whenNotPaused {
    // Payment must be for at least one token.
    if (tokenQuantity_ == 0) {
      revert InvalidTokenQuantity();
    }

    // Payment must be exact.
    if (msg.value != tokenQuantity_ * shippingCost) {
      revert IncorrectPayment();
    }

    emit PaymentCollected(
      msg.sender,
      tokenId_,
      msg.value,
      shippingCost,
      tokenQuantity_
    );
  }

  /**
   * @dev withdraw - Transfer ETH from this contract to the beneficiary.
   */
  function withdraw() external {
    // only owner and beneficiary can call
    if (msg.sender != owner() && msg.sender != beneficiary) {
      revert NotAuthorized();
    }

    (bool success, ) = beneficiary.call{value: address(this).balance}("");
    if (!success) {
      revert TransferFailed();
    }
  }

  function setBeneficiary(address beneficiary_) external onlyOwner {
    beneficiary = beneficiary_;
  }

  /**
   * @dev fallback - The fallback function is executed on a call to the contract if
   * none of the other functions match the given function signature.
   */
  fallback() external payable {
    revert();
  }

  /**
   * @dev receive - revert any random ETH.
   */
  receive() external payable {
    revert();
  }
}