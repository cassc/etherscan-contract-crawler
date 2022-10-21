// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721URIStorageEnumerable.sol";
import "./OwnPause.sol";

contract TokenNft is ERC721URIStorageEnumerable, OwnPause {
  using Strings for uint256;

  // First tokenId begins from 1
  // Also indicate the total number of minted tokens
  uint256 public _tokenId;

  string public _baseExtension = ".json";

  // https://base-link/vip/
  string public _baseTokenURIForVIP;
  // https://base-link/vip/1.json
  uint256 public _currentNumForVIP = 0; // current number of minted tokens for VIP

  // https://base-link/feel-lucky/
  string public _baseTokenURIForFeelLucky;
  // https://base-link/feel-lucky/1.json
  uint256 public _currentNumForFeelLucky = 0; // current number of minted tokens for feel-lucky

  // https://base-link/gallery/
  string public _baseTokenURIForGallery;
  // https://base-link/gallery/1.json
  uint256 public _currentNumForGallery = 0; // current number of minted tokens for gallery

  // https://base-link/reserved/
  string public _baseTokenURIForReserved;
  // https://base-link/reserved/1.json
  uint256 public _currentNumForReserved = 0; // current number of minted tokens for reserved

  event EventMintManyForReserved(address _receiver, uint256 _amount);

  event EventMintForVIP(
    uint256 _tokenId,
    address _tokenOwner,
    string _tokenURI
  );

  event EventMintForFeelLucky(
    uint256 _tokenId,
    address _tokenOwner,
    string _tokenURI
  );

  event EventMintForGallery(
    uint256 _tokenId,
    address _tokenOwner,
    string _tokenURI
  );

  event EventSetBaseTokenURIForVIP(string _baseTokenURIForVIP);
  event EventSetBaseTokenURIForFeelLucky(string _baseTokenURIForFeelLucky);
  event EventSetBaseTokenURIForGallery(string _baseTokenURIForGallery);
  event EventSetBaseTokenURIForReserved(string _baseTokenURIForReserved);

  event EventAdminTransferToken(uint256 tokenId_, address receiver_);

  constructor(
    string memory name_,
    string memory symbol_,
    string memory baseTokenURIForVIP_,
    string memory baseTokenURIForFeelLucky_,
    string memory baseTokenURIForGallery_,
    string memory baseTokenURIForReserved_
  ) ERC721(name_, symbol_) {
    setBaseTokenURIForAll(
      baseTokenURIForVIP_,
      baseTokenURIForFeelLucky_,
      baseTokenURIForGallery_,
      baseTokenURIForReserved_
    );
  }

  // Apply pausable for token transfer
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);

    require(!paused(), "TokenNft: paused");
  }

  function setBaseTokenURIForVIP(string memory baseTokenURIForVIP_)
    public
    isAuthorized
  {
    _baseTokenURIForVIP = baseTokenURIForVIP_;

    emit EventSetBaseTokenURIForVIP(baseTokenURIForVIP_);
  }

  function setBaseTokenURIForFeelLucky(string memory baseTokenURIForFeelLucky_)
    public
    isAuthorized
  {
    _baseTokenURIForFeelLucky = baseTokenURIForFeelLucky_;

    emit EventSetBaseTokenURIForFeelLucky(baseTokenURIForFeelLucky_);
  }

  function setBaseTokenURIForGallery(string memory baseTokenURIForGallery_)
    public
    isAuthorized
  {
    _baseTokenURIForGallery = baseTokenURIForGallery_;

    emit EventSetBaseTokenURIForGallery(baseTokenURIForGallery_);
  }

  function setBaseTokenURIForReserved(string memory baseTokenURIForReserved_)
    public
    isAuthorized
  {
    _baseTokenURIForReserved = baseTokenURIForReserved_;

    emit EventSetBaseTokenURIForReserved(baseTokenURIForReserved_);
  }

  function setBaseTokenURIForAll(
    string memory baseTokenURIForVIP_,
    string memory baseTokenURIForFeelLucky_,
    string memory baseTokenURIForGallery_,
    string memory baseTokenURIForReserved_
  ) public isAuthorized {
    setBaseTokenURIForVIP(baseTokenURIForVIP_);
    setBaseTokenURIForFeelLucky(baseTokenURIForFeelLucky_);
    setBaseTokenURIForGallery(baseTokenURIForGallery_);
    setBaseTokenURIForReserved(baseTokenURIForReserved_);
  }

  function getCurrentNumForVIP() external view returns (uint256) {
    return _currentNumForVIP;
  }

  function getCurrentNumForFeelLucky() external view returns (uint256) {
    return _currentNumForFeelLucky;
  }

  function getCurrentNumForGallery() external view returns (uint256) {
    return _currentNumForGallery;
  }

  function tokenExists(uint256 tokenId_) external view returns (bool) {
    return _exists(tokenId_);
  }

  function mintForVIP(address _receiver) public isAuthorized returns (uint256) {
    _tokenId = _tokenId + 1;
    _safeMint(_receiver, _tokenId);

    _currentNumForVIP++;
    string memory _tokenURI = string(
      abi.encodePacked(
        _baseTokenURIForVIP,
        _currentNumForVIP.toString(),
        _baseExtension
      )
    );

    _setTokenURI(_tokenId, _tokenURI);

    emit EventMintForVIP(_tokenId, _receiver, _tokenURI);

    return _tokenId;
  }

  function mintManyForVIP(address[] memory _receiverList)
    external
    isAuthorized
  {
    for (uint256 i = 0; i < _receiverList.length; i++) {
      mintForVIP(_receiverList[i]);
    }
  }

  // Mint reserved tokens for list
  // Max "_amount" is 20 (otherwise, out-of-gas)
  function mintManyForReserved(address _receiver, uint256 _amount)
    external
    isAuthorized
  {
    for (uint256 i = 0; i < _amount; i++) {
      _tokenId = _tokenId + 1;
      _safeMint(_receiver, _tokenId);

      _currentNumForReserved++;
      string memory _tokenURI = string(
        abi.encodePacked(
          _baseTokenURIForReserved,
          _currentNumForReserved.toString(),
          _baseExtension
        )
      );

      _setTokenURI(_tokenId, _tokenURI);
    }

    emit EventMintManyForReserved(_receiver, _amount);
  }

  function mintForFeelLucky(address _receiver)
    public
    isAuthorized
    returns (uint256)
  {
    _tokenId = _tokenId + 1;
    _safeMint(_receiver, _tokenId);

    _currentNumForFeelLucky++;
    string memory _tokenURI = string(
      abi.encodePacked(
        _baseTokenURIForFeelLucky,
        _currentNumForFeelLucky.toString(),
        _baseExtension
      )
    );

    _setTokenURI(_tokenId, _tokenURI);

    emit EventMintForFeelLucky(_tokenId, _receiver, _tokenURI);

    return _tokenId;
  }

  function mintManyForFeelLucky(address[] memory _receiverList)
    external
    isAuthorized
  {
    for (uint256 i = 0; i < _receiverList.length; i++) {
      mintForFeelLucky(_receiverList[i]);
    }
  }

  function mintForGallery(address _receiver, uint256 _imageId)
    public
    isAuthorized
    returns (uint256)
  {
    _tokenId = _tokenId + 1;
    _safeMint(_receiver, _tokenId);

    _currentNumForGallery++;
    string memory _tokenURI = string(
      abi.encodePacked(
        _baseTokenURIForGallery,
        _imageId.toString(),
        _baseExtension
      )
    );

    _setTokenURI(_tokenId, _tokenURI);

    emit EventMintForGallery(_tokenId, _receiver, _tokenURI);

    return _tokenId;
  }

  function mintManyForGallery(
    address[] memory _receiverList,
    uint256[] memory _imageIdList
  ) external isAuthorized {
    require(
      _receiverList.length == _imageIdList.length,
      "TokenNft: _receiverList and _imageIdList not same length"
    );

    for (uint256 i = 0; i < _receiverList.length; i++) {
      mintForGallery(_receiverList[i], _imageIdList[i]);
    }
  }

  function adminTransferToken(uint256 tokenId_, address receiver_)
    external
    isAuthorized
  {
    require(_exists(tokenId_), "TokenNft: Token not exist");

    address tokenOwner = ownerOf(tokenId_);
    _safeTransfer(tokenOwner, receiver_, tokenId_, "");

    emit EventAdminTransferToken(tokenId_, receiver_);
  }

  function transfer(uint256 tokenId_, address receiver_) public {
    require(ownerOf(tokenId_) == _msgSender(), "TokenNft: Not token owner");

    _safeTransfer(_msgSender(), receiver_, tokenId_, "");
  }

  // Transfer many tokens of msg.sender wallet to another wallet
  function transferMany(uint256[] memory tokenIdList_, address receiver_)
    external
  {
    for (uint256 i = 0; i < tokenIdList_.length; i++) {
      transfer(tokenIdList_[i], receiver_);
    }
  }
}