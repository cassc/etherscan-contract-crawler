// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ISaleable.sol';

abstract contract Saleable is ISaleable {
  mapping(uint256 => address[]) public authorizedSellersByOffer;
  mapping(address => bool) public authorizedSellersAllOffers;

  function isAuthorizedSellerOf(address seller, uint256 offeringId) public view returns (bool) {
    if (authorizedSellersAllOffers[seller]) {
      return true;
    }

    for (uint256 idx = 0; idx < authorizedSellersByOffer[offeringId].length; idx++) {
      if (authorizedSellersByOffer[offeringId][idx] == seller) {
        return true;
      }
    }

    return false;
  }

  function _processSaleOffering(uint256, address, uint256) internal virtual {
    require(false, 'Unimplemented');
  }

  function processSale(uint256 offeringId, address buyer, uint256 price) public override {
    require(isAuthorizedSellerOf(msg.sender, offeringId), 'Seller not authorized');
    _processSaleOffering(offeringId, buyer, price);
  }

  function _registerSeller(uint256 offeringId, address seller) internal {
    require(!isAuthorizedSellerOf(seller, offeringId), 'Seller is already authorized');
    authorizedSellersByOffer[offeringId].push(seller);
  }

  function _registerSeller(address seller) internal {
    authorizedSellersAllOffers[seller] = true;
  }

  function _deregisterSeller(uint256 offeringId, address seller) internal {
    require(isAuthorizedSellerOf(seller, offeringId), 'Seller was not authorized');
    uint256 index = 0;
    for (; index < authorizedSellersByOffer[offeringId].length; index++) {
      if (authorizedSellersByOffer[offeringId][index] == seller) {
        break;
      }
    }

    uint256 len = authorizedSellersByOffer[offeringId].length;
    if (index < len - 1) {
      address temp = authorizedSellersByOffer[offeringId][index];
      authorizedSellersByOffer[offeringId][index] = authorizedSellersByOffer[offeringId][len];
      authorizedSellersByOffer[offeringId][len] = temp;
    }

    authorizedSellersByOffer[offeringId].pop();
  }

  function _deregisterSeller(address seller) internal {
    authorizedSellersAllOffers[seller] = false;
  }

  function getSellersFor(uint256 offeringId) public view override returns (address[] memory sellers) {
    sellers = authorizedSellersByOffer[offeringId];
  }
}