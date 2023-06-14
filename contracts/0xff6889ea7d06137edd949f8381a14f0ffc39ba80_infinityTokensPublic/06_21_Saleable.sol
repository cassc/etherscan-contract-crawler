// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ISaleable.sol";

abstract contract Saleable is ISaleable {
    mapping(uint256 => address[]) public authorizedSellersByOffer;

    function isAuthorizedSellerOf( address seller, uint256 offeringId ) public view returns (bool) {
        for (uint256 idx = 0; idx < authorizedSellersByOffer[offeringId].length; idx++) {
            if (authorizedSellersByOffer[offeringId][idx] == seller) {
                return true;
            }
        }

        return false;
    }

    function _processSaleOffering( uint256 offeringId, address buyer ) internal virtual;

    function processSale( uint256 offeringId, address buyer ) public override {
        require(isAuthorizedSellerOf(msg.sender, offeringId), "Caller is not authorized to sell this offering");
        _processSaleOffering(offeringId, buyer);
        emit SaleProcessed(msg.sender, offeringId, buyer);
    }

    function _registerSeller( uint256 offeringId, address seller) internal {
        require(!isAuthorizedSellerOf(seller, offeringId), "Seller is already authorized");
        authorizedSellersByOffer[offeringId].push(seller);
        
    }

    function _deregisterSeller( uint256 offeringId, address seller) internal {
        require(isAuthorizedSellerOf(seller, offeringId), "Seller was not authorized");
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

    function getSellersFor( uint256 offeringId ) view public override returns ( address [] memory sellers ) {
        sellers = authorizedSellersByOffer[offeringId];
    }
}