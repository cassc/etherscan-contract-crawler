// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./MarketplaceModel.sol";

contract Marketplace is MarketplaceModel {

    // PAYABLE BUYER'S FUNCTION //

    function buyCollectible(address collectibleAddress, uint256 tokenId) external payable 
        whenNotPaused()
        marketIsOpen(collectibleAddress)
        notCollectibleOwner(collectibleAddress, tokenId)
    {
        _buyCollectible(collectibleAddress, tokenId, msg.value);
    }
  
    function enterBidForCollectible(address collectibleAddress, uint256 tokenId) external payable 
        whenNotPaused()
        marketIsOpen(collectibleAddress)
        notCollectibleOwner(collectibleAddress, tokenId)
    {
        require(msg.value > 0); // Bid must be greater than 0

        _enterBidForCollectible(collectibleAddress, tokenId, msg.value);
    }

    /// @dev used by a user who wants to cancel a bid placed by her/him
    function withdrawBidForCollectible(address collectibleAddress, uint256 tokenId) external payable 
        whenNotPaused()
        marketIsOpen(collectibleAddress)
        notCollectibleOwner(collectibleAddress, tokenId)
    {
        _withdrawBidForCollectible(collectibleAddress, tokenId);
    }

    // PAYABLE SELLER FUNCTIONS //

    function offerCollectibleForSale(address collectibleAddress, uint256 tokenId, uint256 minSalePriceInWei) external  
        whenNotPaused()
        marketIsOpen(collectibleAddress)
        onlyCollectibleOwner(collectibleAddress, tokenId)
    {
        _offerCollectibleForSaleToAddress(collectibleAddress, tokenId, minSalePriceInWei, address(0));
    }

    function offerCollectibleForSaleToAddress(address collectibleAddress, uint256 tokenId, uint256 minSalePriceInWei, address toAddress) external 
        whenNotPaused()
        marketIsOpen(collectibleAddress)
        onlyCollectibleOwner(collectibleAddress, tokenId)
    {
        _offerCollectibleForSaleToAddress(collectibleAddress, tokenId, minSalePriceInWei, toAddress);
    }

    function withdrawOfferForCollectible(address collectibleAddress, uint256 tokenId) external 
        whenNotPaused()
        marketIsOpen(collectibleAddress)
        onlyCollectibleOwner(collectibleAddress, tokenId)
    {
        _withdrawOfferForCollectible(collectibleAddress, tokenId);
    }

    function acceptBidForCollectible(address collectibleAddress, uint256 tokenId, uint256 minPrice) external 
        whenNotPaused()
        marketIsOpen(collectibleAddress)
        onlyCollectibleOwner(collectibleAddress, tokenId)
    {
        _acceptBidForCollectible(collectibleAddress, tokenId, minPrice);
    }

    // WITHDRAW ETH //

    function withdraw() external 
        whenNotPaused() 
    {
        _withdraw();
    }
}