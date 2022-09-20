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
/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract ERC721Tradeable is ERC721, ContextMixin, NativeMetaTransaction, Ownable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;


  uint256 internal constant MAX_SUPPLY = 1000;
  uint256 internal constant MAX_PER_TX = 5;
  uint256 internal constant MAX_PER_WL = 2;
  uint256 internal constant MAX_PER_WALLET = 10;
  //price specified in gwei
  uint256 internal constant WL_PRICE = 20000000;
  uint256 internal constant PRICE = 25000000;
  string public _contractURI;
  string internal _baseTokenURI;
  bool internal _isActive;
  bool internal _whitelistPhase;
  string internal name_;
  string internal symbol_;
  address proxyRegistryAddress;
  mapping(address => uint256) internal whitelistMinted;
  
  Counters.Counter internal _nextTokenId;
     
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

    /**
      * @dev Returns the symbol of the token, usually a shorter version of the
      * name.
      */
    function symbol() public view virtual override returns (string memory) {
        return symbol_;
    }

    function mintPriceInWei() public view virtual returns (uint256) {
        return SafeMath.mul(PRICE, 1e9);
    }

    function wlMintPriceInWei() public view virtual returns (uint256) {
        return SafeMath.mul(WL_PRICE, 1e9);
    }
}