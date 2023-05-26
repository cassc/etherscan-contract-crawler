// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./CardBase.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract CardNft is ERC721Enumerable, CardBase {
  // First tokenId begins from 1
  // Also indicate the total number of minted tokens
  uint256 public _tokenId;

  uint256 public _burnCount; // count the number of burnt tokens

  string public _baseTokenURI;

  bool public _tokenTransferPaused;

  event EventMintCard(
    uint256 _tokenId,
    address _tokenOwner,
    uint256 _timestamp
  );

  event EventMintCardMany(
    uint256[] _tokenIdList,
    address _tokenOwner,
    uint256 _timestamp
  );

  event EventAirdrop(uint256 receiverListLength_);

  event EventBurnCard(address _tokenOwner, uint256 tokenId_);
  event EventAdminBurnCard(address _adminAddress, uint256 tokenId_);

  event EventSetTokenTransferPaused(bool tokenTransferPaused_);
  event EventSetBaseURI(string baseURI);
  event EventAdminTransferToken(uint256 tokenId_, address receiver_);

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _baseTokenLink
  ) ERC721(_name, _symbol) {
    _baseTokenURI = _baseTokenLink;
    _tokenTransferPaused = false;
  }

  // Apply pausable for token transfer
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);

    require(_tokenTransferPaused == false, "CardNft: token transfer paused");
  }

  function setTokenTransferPaused(bool tokenTransferPaused_) external isOwner {
    _tokenTransferPaused = tokenTransferPaused_;

    emit EventSetTokenTransferPaused(tokenTransferPaused_);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string memory baseURI) external isOwner {
    _baseTokenURI = baseURI;

    emit EventSetBaseURI(baseURI);
  }

  function tokenExists(uint256 tokenId_) external view returns (bool) {
    return _exists(tokenId_);
  }

  // Return the tokenIds owned by a given user wallet address
  function getTokenIdsOfUserAddress(address _userAddr)
    external
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(_userAddr);

    uint256[] memory tokenIds = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_userAddr, i);
    }
    return tokenIds;
  }

  function burnCard(uint256 tokenId_) external whenNotPaused {
    require(ownerOf(tokenId_) == _msgSender(), "CardNft: Not token owner");
    _burn(tokenId_);
    _burnCount += 1;
    emit EventBurnCard(_msgSender(), tokenId_);
  }

  function adminBurnCard(uint256 tokenId_) external whenNotPaused isOwner {
    _burn(tokenId_);
    _burnCount += 1;
    emit EventAdminBurnCard(_msgSender(), tokenId_);
  }

  function mintCard(address owner_)
    external
    whenNotPaused
    isAuthorized
    returns (uint256)
  {
    _tokenId = _tokenId + 1;
    _safeMint(owner_, _tokenId, "");

    emit EventMintCard(_tokenId, owner_, block.timestamp);

    return _tokenId;
  }

  function mintCardMany(address owner_, uint256 cardAmount_)
    external
    whenNotPaused
    isAuthorized
    returns (uint256[] memory)
  {
    uint256[] memory tokenIds = new uint256[](cardAmount_);

    for (uint256 i = 0; i < cardAmount_; i++) {
      _tokenId = _tokenId + 1;
      _safeMint(owner_, _tokenId, "");

      tokenIds[i] = _tokenId;
    }

    emit EventMintCardMany(tokenIds, owner_, block.timestamp);

    return tokenIds;
  }

  function airdrop(address[] calldata receiverList_)
    external
    whenNotPaused
    isAuthorized
  {
    for (uint256 i = 0; i < receiverList_.length; i++) {
      _tokenId = _tokenId + 1;
      _safeMint(receiverList_[i], _tokenId, "");
    }

    emit EventAirdrop(receiverList_.length);
  }

  function adminTransferToken(uint256 tokenId_, address receiver_)
    external
    isOwner
  {
    require(_exists(tokenId_), "CardNft: Token not exist");

    address tokenOwner = ownerOf(tokenId_);
    _safeTransfer(tokenOwner, receiver_, tokenId_, "");

    emit EventAdminTransferToken(tokenId_, receiver_);
  }

  function transfer(uint256 tokenId_, address receiver_) external {
    require(ownerOf(tokenId_) == _msgSender(), "CardNft: Not token owner");

    _safeTransfer(_msgSender(), receiver_, tokenId_, "");
  }
}