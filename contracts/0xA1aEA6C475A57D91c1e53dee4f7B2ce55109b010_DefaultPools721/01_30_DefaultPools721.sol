// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./Store.sol";

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
contract DefaultPools721 is ERC721Upgradeable, OwnableUpgradeable {
  using SafeMath for uint256;

  address public exchangeAddress;
  address public proxyRegistryAddress;
  string private contractURI_;
  string private _extendedTokenURI;

  mapping(uint256 => string) private _eTokenURIs;

  function initialize(
    string memory _name,
    string memory _symbol,
    string memory _tokenURI,
    string memory _contractURI,
    address _proxyRegistryAddress,
    address _exchangeAddress
  ) external initializer {
    __Ownable_init();
    __ERC721_init(_name, _symbol);
    proxyRegistryAddress = _proxyRegistryAddress;
    _extendedTokenURI = _tokenURI;
    exchangeAddress = _exchangeAddress;
    contractURI_ = _contractURI;

    transferOwnership(tx.origin);
  }

  function setContractURI(string memory _contractURI) external onlyOwner {
    contractURI_ = _contractURI;
  }

  function contractURI() external view returns (string memory) {
    return contractURI_;
  }

  function mintTo(
    address _to,
    uint256 _tokenId,
    string memory _metadataURI
  ) public returns (uint256) {
    _mint(_to, _tokenId);
    _eTokenURIs[_tokenId] = _metadataURI;
    return _tokenId;
  }

  function mintAndTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    string memory _metadataURI
  ) external returns (uint256) {
    if (_exists(_tokenId)) {
      address owner = ownerOf(_tokenId);
      require(owner == _from, "ERC721Tradable::Token ID not belong to user!");
      require(isApprovedForAll(owner, _msgSender()), "ERC721Tradable::sender is not approved!");
      _transfer(_from, _to, _tokenId);
    } else {
      _mint(_to, _tokenId);
      _eTokenURIs[_tokenId] = _metadataURI;
    }

    return _tokenId;
  }

  function singleTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) external returns (uint256) {
    if (_exists(_tokenId)) {
      address owner = ownerOf(_tokenId);
      require(owner == _from, "ERC721Tradable::Token ID not belong to user!");
      require(isApprovedForAll(owner, _msgSender()), "ERC721Tradable::sender is not approved!");
      _transfer(_from, _to, _tokenId);
    }

    return _tokenId;
  }

  function baseTokenURI() public view virtual returns (string memory) {
    return _extendedTokenURI;
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    string memory _tokenURI = _eTokenURIs[_tokenId];
    string memory base = baseTokenURI();

    // If there is no base URI, return the token URI.
    if (bytes(base).length == 0) {
      return _tokenURI;
    }
    // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
    if (bytes(_tokenURI).length > 0) {
      return string(abi.encodePacked(base, _tokenURI));
    }
    // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
    return string(abi.encodePacked(base, Strings.toString(_tokenId)));
  }

  function modifyExtendedURI(string memory extendedTokenURI_) external onlyOwner {
    _extendedTokenURI = extendedTokenURI_;
  }

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
   */
  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner)) == operator) {
      return true;
    }

    return super.isApprovedForAll(owner, operator);
  }
}