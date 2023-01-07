// SPDX-License-Identifier: UNLICENSED
// © Copyright 2021. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.8.5; 

/// @title IGBMInitiator: GBM Auction initiator interface.
/// @dev Will be called when initializing GBM auctions on the main GBM contract. 
/// @author Guillaume Gonnaud and Javier Fraile
interface IGBMInitiator {

    // Auction id either = the contract token address cast as uint256 or 
    // auctionId = uint256(keccak256(abi.encodePacked(_contract, _tokenId, _tokenKind)));  <= ERC721
    // auctionId = uint256(keccak256(abi.encodePacked(_contract, _tokenId, _tokenKind, _1155Index))); <= ERC1155

    function getStartTime(uint256 _auctionId) external view returns(uint256);

    function getEndTime(uint256 _auctionId) external view returns(uint256);

    function getHammerTimeDuration(uint256 _auctionId) external view returns(uint256);

    function getBidDecimals(uint256 _auctionId) external view returns(uint256);

    function getStepMin(uint256 _auctionId) external view returns(uint256);

    function getIncMin(uint256 _auctionId) external view returns(uint256);

    function getIncMax(uint256 _auctionId) external view returns(uint256);

    function getBidMultiplier(uint256 _auctionId) external view returns(uint256);
    

}