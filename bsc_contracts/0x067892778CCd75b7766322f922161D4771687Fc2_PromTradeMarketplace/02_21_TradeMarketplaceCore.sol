// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./TradeMarketplaceOffers.sol";

contract TradeMarketplaceCore is ReentrancyGuard, TradeMarketplaceOffers {
  /** 
   @notice Method for listing NFT
   @param _nftAddress Address of NFT token for sale
   @param _tokenId Token ID of NFT token for sale
   @param _quantity token amount to list (needed for ERC-1155 NFTs, set as 1 for ERC-721)
   @param _payToken Paying token
   @param _pricePerItem sale price for an iteam
   @param _startingTime starting timestamp after which item may be bought
   @param _endTime end timestamp after which item after which item may not be bough anymore
  */
  function listItem(
    address _nftAddress,
    uint256 _tokenId,
    uint256 _quantity,
    address _payToken,
    uint256 _pricePerItem,
    uint256 _startingTime,
    uint256 _endTime
  ) public onlyAssetOwner(_nftAddress, _tokenId, _quantity) {
    _checkListing(_nftAddress, _tokenId, msg.sender, _payToken, _quantity);

    listings[_nftAddress][_tokenId][msg.sender] = Listing({
      quantity: _quantity,
      payToken: _payToken,
      pricePerItem: _pricePerItem,
      startingTime: _startingTime,
      endTime: _endTime,
      nonce: block.number
    });
    emit ItemListed(
      msg.sender,
      _nftAddress,
      _tokenId,
      _quantity,
      _payToken,
      _pricePerItem,
      _startingTime,
      _endTime
    );
  }

  /// @notice Method for canceling listed NFT
  function cancelListing(address _nftAddress, uint256 _tokenId)
    public
    isListed(_nftAddress, _tokenId, msg.sender)
    onlyAssetOwner(
      _nftAddress,
      _tokenId,
      listings[_nftAddress][_tokenId][msg.sender].quantity
    )
  {
    delete (listings[_nftAddress][_tokenId][msg.sender]);
    emit ItemCanceled(msg.sender, _nftAddress, _tokenId);
  }

  /** 
   @notice Method for updating listed NFT for sale
   @param _nftAddress Address of NFT token for sale
   @param _tokenId Token ID of NFT token for sale
   @param _payToken payment token
   @param _newPricePerItem New sale price for the item
  */

  function updateListing(
    address _nftAddress,
    uint256 _tokenId,
    address _payToken,
    uint256 _newPricePerItem
  )
    external
    isListed(_nftAddress, _tokenId, msg.sender)
    onlyAssetOwner(
      _nftAddress,
      _tokenId,
      listings[_nftAddress][_tokenId][msg.sender].quantity
    )
  {
    Listing storage listedItem = listings[_nftAddress][_tokenId][msg.sender];

    _validPayToken(_payToken);

    listedItem.payToken = _payToken;
    listedItem.pricePerItem = _newPricePerItem;
    listedItem.nonce = block.number;
    emit ItemUpdated(
      msg.sender,
      _nftAddress,
      _tokenId,
      _payToken,
      _newPricePerItem
    );
  }

  /** 
   @notice Method for buying listed NFT
   @param _nftAddress Address of NFT token for sale
   @param _tokenId Token Id of NFT token for sale
   @param _owner listing's creator (owner of the item)
   @param _nonce nonce of the listing. Can be found by calling listings mapping
  */
  function buyItem(
    address _nftAddress,
    uint256 _tokenId,
    address _owner,
    uint256 _nonce
  )
    public
    payable
    whenNotPaused
    nonReentrant
    isListed(_nftAddress, _tokenId, _owner)
    validListing(_nftAddress, _tokenId, _owner)
  {
    Listing memory listedItem = listings[_nftAddress][_tokenId][_owner];

    _handleListingPayment(listedItem, _owner, _nftAddress);

    _transferNft(
      _nftAddress,
      _owner,
      msg.sender,
      _tokenId,
      listedItem.quantity
    );

    require(
      listings[_nftAddress][_tokenId][_owner].nonce == _nonce,
      "listing was updated"
    );

    emit ItemSold(
      _owner,
      msg.sender,
      _nftAddress,
      _tokenId,
      listedItem.quantity,
      listedItem.payToken,
      listedItem.pricePerItem
    );
    delete (listings[_nftAddress][_tokenId][_owner]);
  }

  /** 
   @notice Method for buying listed NFT. This method takes payment in a PROM token instead of listing paymentToken
   @param _nftAddress Address of NFT token for sale
   @param _tokenId Token Id of NFT token for sale
   @param _owner listing's creator (owner of the item)
   @param _nonce nonce of the listing. Can be found by calling listings mapping
  */
  function buyItemWithFeeInProm(
    address _nftAddress,
    uint256 _tokenId,
    address _owner,
    uint256 _nonce
  )
    public
    payable
    nonReentrant
    whenNotPaused
    isListed(_nftAddress, _tokenId, _owner)
    validListing(_nftAddress, _tokenId, _owner)
  {
    require(promToken != address(0), "prom fees not enabled");
    Listing memory listedItem = listings[_nftAddress][_tokenId][_owner];

    _handleListingPaymentProm(listedItem, _owner, _nftAddress);

    _transferNft(
      _nftAddress,
      _owner,
      msg.sender,
      _tokenId,
      listedItem.quantity
    );

    require(
      listings[_nftAddress][_tokenId][_owner].nonce == _nonce,
      "listing was updated"
    );

    emit ItemSold(
      _owner,
      msg.sender,
      _nftAddress,
      _tokenId,
      listedItem.quantity,
      listedItem.payToken,
      listedItem.pricePerItem
    );
    delete (listings[_nftAddress][_tokenId][_owner]);
  }
}