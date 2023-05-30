// SPDX-License-Identifier: UNLICENSED

// ███╗   ███╗ █████╗ ██████╗ ███████╗   ██╗    ██╗██╗████████╗██╗  ██╗   ███╗   ███╗ █████╗ ███████╗ ██████╗ ███╗   ██╗
// ████╗ ████║██╔══██╗██╔══██╗██╔════╝   ██║    ██║██║╚══██╔══╝██║  ██║   ████╗ ████║██╔══██╗██╔════╝██╔═══██╗████╗  ██║
// ██╔████╔██║███████║██║  ██║█████╗     ██║ █╗ ██║██║   ██║   ███████║   ██╔████╔██║███████║███████╗██║   ██║██╔██╗ ██║
// ██║╚██╔╝██║██╔══██║██║  ██║██╔══╝     ██║███╗██║██║   ██║   ██╔══██║   ██║╚██╔╝██║██╔══██║╚════██║██║   ██║██║╚██╗██║
// ██║ ╚═╝ ██║██║  ██║██████╔╝███████╗   ╚███╔███╔╝██║   ██║   ██║  ██║   ██║ ╚═╝ ██║██║  ██║███████║╚██████╔╝██║ ╚████║
// ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝    ╚══╝╚══╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝

pragma solidity ^0.8.15;

import "./mason/utils/Administrable.sol";
import "./mason/utils/Lockable.sol";
import "./mason/utils/Toggleable.sol";
import "./mason/utils/EIP712Common.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import { Base64 } from "./Base64.sol";
import { Utils } from "./Utils.sol";

error ExceedsMaxPerWallet();
error AlreadyOnTheList();
error InvalidTokenId();
error InsufficientPayment();

contract FloorAppPass is ERC721A, ERC721ABurnable, Lockable, Toggleable, Administrable, EIP712Common{
  using EnumerableSet for EnumerableSet.UintSet;

  uint256 public maxPerWallet = 3;
  uint256 public tokenPrice = 200000000;

  // The maximum TokenID that is currently active
  uint256 public currentMaximum;

  // This is the list of tokens which we have moved to the front of the line.
  // It is intended for one-off usage vs en-mass line skipping.
  EnumerableSet.UintSet private _skipList;

  address private royaltyAddress;
  address private treasuryAddress;

  uint256 private royaltyPercent;

  constructor (
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _baseImageURI,
    address _treasuryAddress,
    uint256 _royaltyPercent
  ) ERC721A(_tokenName, _tokenSymbol) {
    baseImageURI = _baseImageURI;

    royaltyAddress = _treasuryAddress;
    royaltyPercent = _royaltyPercent;

    treasuryAddress = _treasuryAddress;

    _setRoyalties(_treasuryAddress, _royaltyPercent);
  }

  // ------ MINTING -----------------------------------------------------------

  function mint(uint256 _count) external payable noContracts requireActiveSale requireActiveContract {
    if(_numberMinted(msg.sender) + _count > maxPerWallet) revert ExceedsMaxPerWallet();
    if(msg.value < tokenPrice * _count) revert InsufficientPayment();

    _mint(msg.sender, _count);
  }

  function whitelistMint(uint256 _count, bytes calldata _signature) external payable requiresWhitelist(_signature) noContracts requireActiveWhitelist  requireActiveContract {
    if(_numberMinted(msg.sender) + _count > maxPerWallet) revert ExceedsMaxPerWallet();
    if(msg.value < tokenPrice * _count) revert InsufficientPayment();

    _mint(msg.sender, _count);
  }

  // ------ AIRDROPS ----------------------------------------------------------

  function airdrop(uint256 _count, address _recipient) external requireActiveContract onlyOperatorsAndOwner {
    _mint(_recipient, _count);
  }

  function airdropBatch(uint256[] calldata _counts, address[] calldata _recipients) external requireActiveContract onlyOperatorsAndOwner {
    for (uint256 i; i < _recipients.length;) {
      _mint(_recipients[i], _counts[i]);
      unchecked { ++i; }
    }
  }

  // ------ LINE MANAGEMENT ---------------------------------------------------

  function letPeopleIn(uint256 _count) external onlyOperatorsAndOwner {
    uint256 skippedTokens;
    uint256 newMaximum = currentMaximum + _count;

    for(uint256 i = 0; i < _skipList.length();) {
      if(_skipList.at(i) <= newMaximum) {
        unchecked { ++skippedTokens; }
      }
      unchecked { ++i; }
    }

    currentMaximum = newMaximum + skippedTokens;
  }

  function skipTheLine(uint256 _tokenId) external onlyOperatorsAndOwner {
    if(!_exists(_tokenId)) revert InvalidTokenId();
    if(_tokenId <= currentMaximum) revert AlreadyOnTheList();

    if(_tokenId == currentMaximum + 1) {
      unchecked { ++currentMaximum; }
    }

    _skipList.add(_tokenId);
  }

  function currentStartOfLine() public view returns (uint256) {
    return currentMaximum + 1;
  }

  function _isLive(uint256 tokenId) internal view returns (bool) {
    return tokenId < currentMaximum + 1 || _skipList.contains(tokenId);
  }

  function _placeInLine(uint256 tokenId) internal view returns (uint256) {
    if(_isLive(tokenId)) return 0;

    uint256 underMaximum;
    for(uint256 i = 1; i < tokenId;) {
      if(_skipList.contains(i) && i > currentMaximum) {
        unchecked { ++underMaximum; }
      }
      unchecked { ++i; }
    }

    return tokenId - currentMaximum - underMaximum;
  }

  // ------ ADMINISTRATION ----------------------------------------------------

  function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
    maxPerWallet = _maxPerWallet;
  }

  function setTokenPrice(uint256 _tokenPrice) external onlyOwner {
    tokenPrice = _tokenPrice;
  }

  function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
    treasuryAddress = _treasuryAddress;
  }

  function getTreasuryAddress() public view returns (address) {
    return treasuryAddress;
  }

  // ------ TOKEN METADATA ----------------------------------------------------

  string private baseImageURI;
  string private imageExtension = ".jpg";
  string private externalUrl = "https://www.floornfts.io";
  string private tokenDescription = "The Floor App Pass unlocks the Floor app for iOS & Android (in beta) and grants access to Floor App Pass channels in the Floor Discord.\\n\\nLearn more, and get started at https://floor.link/app-pass-nft";
  string private tokenName = "Floor App Pass";

  function getBaseImageURI() public view returns (string memory) {
    return baseImageURI;
  }

  function getExternalUrl() public view returns (string memory) {
    return externalUrl;
  }

  function getImageExtension() public view returns (string memory) {
    return imageExtension;
  }

  function getTokenDescription() public view returns (string memory) {
    return tokenDescription;
  }

  function getTokenName() public view returns (string memory) {
    return tokenName;
  }

  function setBaseImageURI(string memory _baseImageURI) external onlyOwner {
    baseImageURI = _baseImageURI;
  }

  function setExternalUri(string memory _externalUrl) external onlyOwner {
    externalUrl = _externalUrl;
  }

  function setImageExtension(string memory _imageExtension) external onlyOwner {
    imageExtension = _imageExtension;
  }

  function setTokenDescription(string memory _tokenDescription) external onlyOwner {
    tokenDescription = _tokenDescription;
  }

  function setTokenName(string memory _tokenName) external onlyOwner {
    tokenName = _tokenName;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
    bool isLive = _isLive(tokenId);

    string memory attributes;
    if(isLive) {
      attributes = string(abi.encodePacked(
        '[ { "trait_type": "Active", "value": "',
        isLive ? 'True' : 'False',
        '"}]'));
    } else {
      attributes = string(abi.encodePacked(
        '[ { "trait_type": "Place Number", "value": "',
        Utils.uintToString(_placeInLine(tokenId)),
        '"}, { "trait_type": "Active", "value": "',
        isLive ? 'True' : 'False',
        '"}]'));
    }

    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name": "',
                tokenName,
                '", "description": "',
                tokenDescription,
                '", "external_url": "',
                externalUrl,
                '", "image":"',
                _imageURI(tokenId),
                '", "attributes":',
                attributes,
                '}'
              )
            )
          )
        )
      );
  }

  function _imageURI(uint256 tokenId) internal view returns(string memory) {
    string memory uri;
    if(tokenId <= currentMaximum) {
      uri = string.concat(baseImageURI, "0", imageExtension);
    } else {
      uri = string.concat(baseImageURI,  Utils.uintToString(_placeInLine(tokenId)), imageExtension);
    }

    return uri;
  }

  // ------ ROYALTIES  & PAYMENT-----------------------------------------------

  function _setRoyalties(address _receiver, uint256 _percentage) internal {
    royaltyAddress = _receiver;
    royaltyPercent = _percentage;
  }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
    receiver = royaltyAddress;

    // This sets percentages by price * percentage / 100
    royaltyAmount = _salePrice * royaltyPercent / 100;
  }

  function release() external onlyOwner {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(treasuryAddress), balance);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC721A, AccessControlEnumerable) returns (bool) {
    return ERC721A.supportsInterface(interfaceId);
  }
}