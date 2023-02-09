// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.8.7;

import "./TradeMarketplaceGuard.sol";

contract TradeMarketplaceValidator is TradeMarketplaceGuard {
  /**
    @notice Validate and cancel listing
    @dev Only bundle marketplace can access
    @param _nftAddress address of the NFT which will be sold
    @param _tokenId token id of the NFT which will be sold
    @param _seller address of the seller
   */
  function validateItemSold(
    address _nftAddress,
    uint256 _tokenId,
    address _seller
  ) external onlyBundleMarketplace {
    Listing memory item = listings[_nftAddress][_tokenId][_seller];
    if (item.quantity > 0) {
      delete (listings[_nftAddress][_tokenId][_seller]);
      emit ItemSoldInBundle(msg.sender, _nftAddress, _tokenId);
    }
  }
}