pragma solidity ^0.8.4;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract FlightForcePayments is PaymentSplitter {
  constructor(
    address[] memory payees, 
    uint256[] memory shares
  ) PaymentSplitter(payees, shares) {}
}