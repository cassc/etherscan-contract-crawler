//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./Stampu.sol";

////////////////////////////////////////////////////////////////////
//  ____  _                              ____  _                  //
// / ___|| |_ __ _ _ __ ___  _ __  _   _/ ___|| |_ ___  _ __ ___  //
// \___ \| __/ _` | '_ ` _ \| '_ \| | | \___ \| __/ _ \| '__/ _ \ //
//  ___) | || (_| | | | | | | |_) | |_| |___) | || (_) | | |  __/ //
// |____/ \__\__,_|_| |_| |_| .__/ \__,_|____/ \__\___/|_|  \___| //
//                          |_|                                   //
////////////////////////////////////////////////////////////////////
contract StampuStore is Context, ERC1155Holder, Ownable {
  using ECDSA for bytes32;

  struct StampuInfo {
    uint256 price;
    address payable artist;
    uint16 tokenType;
    uint16 buyLimit; // per transaction buy limit
    uint16 presaleBalance; // balance left for presale
    uint8 platformFee; // out of 100
  }

  Stampu public stampu;
  address public whitelistAdmin;
  mapping(uint256 => StampuInfo) public tokenIdToStampuInfo;
  // Presale purchase history (address => token type => amount)
  mapping(address => mapping(uint256 => uint256)) public presaleTokenTypeHistory;
  mapping(uint256 => bool) public presaleActive;
  mapping(uint256 => bool) public publicSaleActive;

  constructor(address _stampuAddress, address _whitelistAdmin) {
    stampu = Stampu(_stampuAddress);
    whitelistAdmin = _whitelistAdmin;
  }

  function setStampuAddress(address _stampuAddress) public onlyOwner {
    stampu = Stampu(_stampuAddress);
  }

  function setWhitelistAdmin(address _whitelistAdmin) public onlyOwner {
    whitelistAdmin = _whitelistAdmin;
  }

  function addStampuInfo(uint256[] calldata tokenIds, StampuInfo[] calldata stampuInfoList) public onlyOwner {
    require(tokenIds.length == stampuInfoList.length, "StampuStore: input lengths do not match");

    for (uint256 i = 0; i < stampuInfoList.length; i++) {
      StampuInfo memory stampuInfo = stampuInfoList[i];
      require(stampuInfo.platformFee <= 100, "StampuStore: invalid platform fee");
      tokenIdToStampuInfo[tokenIds[i]] = stampuInfoList[i];
    }
  }

  function setPresaleActive(uint256[] calldata _tokenTypes, bool _active) public onlyOwner {
    for (uint256 i = 0; i < _tokenTypes.length; i++) {
      presaleActive[_tokenTypes[i]] = _active;
    }
  }

  function setPublicSaleActive(uint256[] calldata _tokenTypes, bool _active) public onlyOwner {
    for (uint256 i = 0; i < _tokenTypes.length; i++) {
      publicSaleActive[_tokenTypes[i]] = _active;
    }
  }

  function buyPresale(
    uint256 _id,
    uint256 _amount,
    uint256 _tokenTypeLimit,
    bytes memory _sig
  ) public payable {
    StampuInfo storage stampuInfo = tokenIdToStampuInfo[_id];
    uint256 tokenType = stampuInfo.tokenType;
    require(presaleActive[stampuInfo.tokenType], "StampuStore: presale is not active");
    checkWhitelisted(_id, tokenType, _tokenTypeLimit, _sig);

    require(_amount <= stampuInfo.presaleBalance, "StampuStore: insufficient balance left for presale");
    stampuInfo.presaleBalance -= uint16(_amount);

    uint256 prevAmount = presaleTokenTypeHistory[_msgSender()][stampuInfo.tokenType];
    require(prevAmount + _amount <= _tokenTypeLimit, "StampuStore: exceeds the maximum allowed amount for type");
    presaleTokenTypeHistory[_msgSender()][stampuInfo.tokenType] += _amount;

    _buy(_id, _amount);
  }

  function buyPublic(uint256 _id, uint256 _amount) public payable {
    StampuInfo storage stampuInfo = tokenIdToStampuInfo[_id];
    require(publicSaleActive[stampuInfo.tokenType], "StampuStore: public sale is not active");
    _buy(_id, _amount);
  }

  function _buy(uint256 _id, uint256 _amount) private {
    require(_amount <= tokenIdToStampuInfo[_id].buyLimit, "StampuStore: exceeds allowed buy limit");

    StampuInfo memory stampuInfo = tokenIdToStampuInfo[_id];
    require(_amount <= stampu.balanceOf(address(this), _id), "StampuStore: insufficient store balance");
    require(msg.value >= stampuInfo.price * _amount, "StampuStore: insufficient eth amount");

    uint256 artistAmount = _getArtistAmount(stampuInfo.price, _amount, stampuInfo.platformFee);
    (bool success, ) = stampuInfo.artist.call{value: artistAmount}("");
    require(success, "StampuStore: artist payment failed");
    stampu.safeTransferFrom(address(this), _msgSender(), _id, _amount, "");
  }

  function safeTransferFrom(
    address to,
    uint256 id,
    uint256 amount
  ) public onlyOwner {
    stampu.safeTransferFrom(address(this), to, id, amount, "");
  }

  function safeBatchTransferFrom(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts
  ) public onlyOwner {
    stampu.safeBatchTransferFrom(address(this), to, ids, amounts, "");
  }

  function withdrawFees() public onlyOwner {
    (bool sent, ) = msg.sender.call{value: address(this).balance}("");
    require(sent, "StampuStore: failed to send collected fees");
  }

  function _getArtistAmount(
    uint256 price,
    uint256 amount,
    uint8 platformFee
  ) internal pure returns (uint256) {
    return ((price * (100 - platformFee)) / 100) * amount;
  }

  function _isWhitelisted(bytes32 _rawHash, bytes memory _sig) internal view returns (bool) {
    bytes32 msgHash = _rawHash.toEthSignedMessageHash();
    return msgHash.recover(_sig) == whitelistAdmin;
  }

  function checkWhitelisted(
    uint256 _id,
    uint256 _tokenType,
    uint256 _tokenTypeLimit,
    bytes memory _sig
  ) internal view {
    bytes32 rawHash = keccak256(abi.encodePacked(_msgSender(), _id, _tokenType, _tokenTypeLimit));
    require(_isWhitelisted(rawHash, _sig), "StampuStore: not whitelisted or invalid signature");
  }
}