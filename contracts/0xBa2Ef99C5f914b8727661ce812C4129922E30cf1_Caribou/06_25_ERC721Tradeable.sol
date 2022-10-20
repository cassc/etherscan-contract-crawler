// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";
                                                                 
contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract ERC721Tradeable is ERC721, ContextMixin, NativeMetaTransaction, Ownable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  //Price is 0.008 ETH
  uint256 internal PRICE = 8000000;
  string public _contractURI;
  string internal _baseTokenURI;
  bool internal _isActive;
  string internal name_;
  string internal symbol_;
  uint256 internal MAX_FREE = 1;
  address proxyRegistryAddress;
  uint256 internal constant MAX_SUPPLY = 333;
  uint256 internal constant MAX_PER_TX = 5;
  uint256 internal constant MAX_PER_WALLET = 10;
  address[] allowlist = [0x67C9B9ada2FefEfaCefa05d98d7a22a0186D6D27, 0x1A904566f43B24C970b27f3BCD8C55833F63e828, 0xc1160105979bD8A7E39437D4E92b7996a99D0950];
  mapping (address => bool) internal approvedAddresses;
  Counters.Counter internal _nextTokenId;
  Counters.Counter internal genMints;
    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _nextTokenId.increment();
        _initializeEIP712(_name);
        name_ = _name;
        symbol_ = _symbol;
        for(uint i; i < allowlist.length; i++) {
          approvedAddresses[allowlist[i]] = true;
        }
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal override {
      _safeMint(to, tokenId, data);
    }

    function name() public view virtual override returns (string memory) {
        return name_;
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        //metadata
        string memory base = _baseTokenURI;
        return string.concat(
          string.concat(base, Strings.toString(id)),
          ".json");
    }

    function setFreePerWallet(uint256 amount) public onlyOwner {
      MAX_FREE = amount;
    }

    function setMintPriceInGWei(uint256 price) public onlyOwner {
      PRICE = price;
    }

    function symbol() public view virtual override returns (string memory) {
        return symbol_;
    }

    function mintPriceInWei() public view virtual returns (uint256) {
        return SafeMath.mul(PRICE, 1e9);
    }

    function maxFree() public view virtual returns (uint256) {
        return MAX_FREE;
    }
}