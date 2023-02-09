// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.8.7;

import "./TradeMarketplaceUtils.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TradeMarketplaceOffers is TradeMarketplaceUtils, ReentrancyGuard {
  /** 
   @notice Method for offering item
   @param _nftAddress NFT contract address
   @param _tokenId TokenId
   @param _payToken Paying token
   @param _quantity Quantity of items
   @param _pricePerItem Price per item
   @param _deadline Offer expiration
  */
  function createOffer(
    address _nftAddress,
    uint256 _tokenId,
    IERC20 _payToken,
    uint256 _quantity,
    uint256 _pricePerItem,
    uint256 _deadline
  ) external offerNotExists(_nftAddress, _tokenId, msg.sender) {
    require(
      IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721) ||
        IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155),
      "invalid nft address"
    );

    require(_deadline > block.timestamp, "invalid expiration");

    _validPayToken(address(_payToken));
    require(
      address(_payToken) != address(0),
      "only erc20 supported for offers"
    );
    require(
      _payToken.allowance(msg.sender, address(this)) >=
        _pricePerItem * _quantity,
      "allowance is too smal"
    );

    offers[_nftAddress][_tokenId][msg.sender] = Offer(
      _payToken,
      _quantity,
      _pricePerItem,
      _deadline,
      block.timestamp
    );

    emit OfferCreated(
      msg.sender,
      _nftAddress,
      _tokenId,
      _quantity,
      address(_payToken),
      _pricePerItem,
      _deadline
    );
  }

  /** 
  @notice Method for canceling the offer
  @param _nftAddress NFT contract address
  @param _tokenId TokenId
  */
  function cancelOffer(address _nftAddress, uint256 _tokenId)
    external
    offerExists(_nftAddress, _tokenId, msg.sender)
  {
    delete (offers[_nftAddress][_tokenId][msg.sender]);
    emit OfferCanceled(msg.sender, _nftAddress, _tokenId);
  }

  /** 
   @notice Method for accepting the offer
   @param _nftAddress NFT contract address
   @param _tokenId TokenId
   @param _creator Offer creator address
  */
  function acceptOffer(
    address _nftAddress,
    uint256 _tokenId,
    address _creator,
    uint256 _offerNonce
  )
    external
    offerExists(_nftAddress, _tokenId, _creator)
    onlyAssetOwner(
      _nftAddress,
      _tokenId,
      offers[_nftAddress][_tokenId][_creator].quantity
    )
    nonReentrant
  {
    Offer memory offer = offers[_nftAddress][_tokenId][_creator];
    uint16 fee = _checkCollection(_nftAddress);
    _handleOfferPayment(offer, _creator, _nftAddress, fee);

    _transferNft(_nftAddress, msg.sender, _creator, _tokenId, offer.quantity);

    require(offer.offerNonce == _offerNonce, "offer was changed");
    emit ItemSold(
      msg.sender,
      _creator,
      _nftAddress,
      _tokenId,
      offer.quantity,
      address(offer.payToken),
      offer.pricePerItem
    );
    emit OfferCanceled(_creator, _nftAddress, _tokenId);

    delete (listings[_nftAddress][_tokenId][msg.sender]);
    delete (offers[_nftAddress][_tokenId][_creator]);
  }
}