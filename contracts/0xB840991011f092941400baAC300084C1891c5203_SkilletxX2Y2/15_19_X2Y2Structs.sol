// SPDX-License-Identifier: Skillet Group
pragma solidity ^0.8.0;

import "../interfaces/IXY3.sol";

struct X2Y2Loan {
  IXY3.Offer offer;
  IXY3.Signature lenderSignature;
  IXY3.Signature brokerSignature;
  IXY3.CallData extraDeal;
  bool isCollectionOffer;
}