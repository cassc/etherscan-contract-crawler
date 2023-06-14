// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISaleable {
    function processSale( uint256 offeringId, address buyer ) external;
    function getSellersFor( uint256 offeringId ) external view returns ( address [] memory sellers);
 
    event SaleProcessed(address indexed seller, uint256 indexed offeringId, address buyer);
    event SellerAdded(address indexed seller, uint256 indexed offeringId);
    event SellerRemoved(address indexed seller, uint256 indexed offeringId);
}