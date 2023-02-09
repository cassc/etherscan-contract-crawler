// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.8.7;

import "./TradeMarketplaceStorage.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract TradeMarketplaceGuard is
  TradeMarketplaceStorage,
  Pausable,
  AccessControl
{
  modifier onlyBundleMarketplace() {
    require(
      address(addressRegistry.bundleMarketplace()) == msg.sender,
      "sender must be bundle marketplace"
    );
    _;
  }

  modifier onlyAssetOwner(
    address _nftAddress,
    uint256 _tokenId,
    uint256 _quantity
  ) {
    if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
      IERC721 nft = IERC721(_nftAddress);
      require(nft.ownerOf(_tokenId) == msg.sender, "not owning item");
      require(
        nft.isApprovedForAll(msg.sender, address(this)) ||
          IERC721(_nftAddress).getApproved(_tokenId) == address(this),
        "item not approved"
      );
    } else if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155)) {
      IERC1155 nft = IERC1155(_nftAddress);
      require(
        nft.balanceOf(msg.sender, _tokenId) >= _quantity,
        "must hold enough nfts"
      );
      require(
        nft.isApprovedForAll(msg.sender, address(this)),
        "item not approved"
      );
    } else {
      revert("invalid nft address");
    }
    _;
  }

  // TODO: Change
  modifier validListing(
    address _nftAddress,
    uint256 _tokenId,
    address _owner
  ) {
    Listing memory listedItem = listings[_nftAddress][_tokenId][_owner];

    _validOwner(_nftAddress, _tokenId, _owner, listedItem.quantity);

    require(
      block.timestamp >= listedItem.startingTime &&
        block.timestamp <= listedItem.endTime,
      "item not buyable"
    );
    _;
  }

  modifier offerExists(
    address _nftAddress,
    uint256 _tokenId,
    address _creator
  ) {
    Offer memory offer = offers[_nftAddress][_tokenId][_creator];
    require(
      offer.quantity > 0 && offer.deadline > block.timestamp,
      "offer not exists or expired"
    );
    _;
  }

  modifier offerNotExists(
    address _nftAddress,
    uint256 _tokenId,
    address _creator
  ) {
    Offer memory offer = offers[_nftAddress][_tokenId][_creator];
    require(
      offer.quantity == 0 || offer.deadline <= block.timestamp,
      "offer already created"
    );
    _;
  }

  modifier isListed(
    address _nftAddress,
    uint256 _tokenId,
    address _owner
  ) {
    Listing memory listing = listings[_nftAddress][_tokenId][_owner];
    require(listing.quantity > 0, "not listed item");
    _;
  }

  function _validOwner(
    address _nftAddress,
    uint256 _tokenId,
    address _owner,
    uint256 _quantity
  ) internal view {
    if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
      IERC721 nft = IERC721(_nftAddress);
      require(nft.ownerOf(_tokenId) == _owner, "not owning item");
    } else if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155)) {
      IERC1155 nft = IERC1155(_nftAddress);
      require(nft.balanceOf(_owner, _tokenId) >= _quantity, "not owning item");
    } else {
      revert("invalid nft address");
    }
  }

  /**
     @notice Update PromAddressRegistry contract
     @dev Only admin
     @param _registry new adress to be set for AdressRegistry
     */
  function updateAddressRegistry(address _registry)
    external
    onlyRole(ADMIN_SETTER)
  {
    addressRegistry = IPromAddressRegistry(_registry);
  }

  /** 
  @notice Method for setting royalty
  @param _nftAddress NFT contract address
  @param _royalty Royalty
  @param _feeRecipient address where the fees will be sent to
  */
  function registerCollectionRoyalty(
    address _nftAddress,
    uint16 _royalty,
    address _feeRecipient
  ) external onlyRole(ADMIN_SETTER) {
    require(_royalty <= 10000, "invalid royalty");
    require(_feeRecipient != address(0), "invalid fee recipient address");

    collectionRoyalties[_nftAddress] = CollectionRoyalty(
      _royalty,
      _feeRecipient
    );
  }

  function updatePromFeeDiscount(uint16 _newFee)
    external
    onlyRole(ADMIN_SETTER)
  {
    promFeeDiscount = _newFee;
  }

  function updateOracle(address _newOracle) external onlyRole(ADMIN_SETTER) {
    oracle = IPromOracle(_newOracle);
  }

  function togglePause() external onlyRole(PAUSER) {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }
}