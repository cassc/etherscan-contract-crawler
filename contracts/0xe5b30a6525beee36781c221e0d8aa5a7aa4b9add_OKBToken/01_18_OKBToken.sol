// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

import "./ProxyRegistry.sol";

contract OKBToken is ERC721A, Ownable, PaymentSplitter, ReentrancyGuard {
  using SafeMath for uint256;
  using Address for address;
  using Strings for uint256;

  uint256 public maxSupply = 5000;

  string public baseURI = "";
  address public proxyRegistryAddress = address(0);
  
  uint256 public mintPrice = 9000000000000000;
  uint16 public mintLimit = 20;
  bool public mintIsActive = false;

  address[] payees = [
    0xbe68DC6Fd565c7A2aDbB11d1CF6989a26ee16Da0,
    0x85E8e7D76EB35052a7ffef9A04E8CD5c6f78a4dB
  ];

  uint256[] payeeShares = [
    50,
    50 
  ];

  constructor(address _proxyRegistryAddress)
    ERC721A("Okay Kaiju Bears", "OKB")
    PaymentSplitter(payees, payeeShares)
  {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  function tokensRemaining() public view returns (uint256) {
    uint256 ts = totalSupply();
    uint256 available = maxSupply.sub(ts);
    return available;
  }

  function mint(uint16 _quantity) external payable nonReentrant {
    require(mintIsActive, "invalid mint inactive");
    require(_quantity > 0 && _quantity <= mintLimit && _quantity <= tokensRemaining(), "invalid mint quantity");
    require(msg.value >= mintPrice.mul(_quantity), "invalid mint value");
    _safeMint(_msgSender(), _quantity);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "invalid token");
        
    string memory __baseURI = _baseURI();
    return bytes(__baseURI).length > 0 ? string(abi.encodePacked(__baseURI, _tokenId.toString(), ".json")) : '.json';
  }

  function isApprovedForAll(address _owner, address _operator) override public view returns (bool) {
    if (address(proxyRegistryAddress) != address(0)) {
      ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
      if (address(proxyRegistry.proxies(_owner)) == _operator) {
        return true;
      }
    }
    return super.isApprovedForAll(_owner, _operator);
  }

  function setBaseURI(string memory _baseUri) external onlyOwner {
    baseURI = _baseUri;
  }

  function reduceMaxSupply(uint256 _maxSupply) external onlyOwner {
    require(_maxSupply < maxSupply, "less than max supply");
    require(_maxSupply >= totalSupply(), "greater than total supply");
    maxSupply = _maxSupply;
  }

  function setMintPrice(uint256 _mintPrice) external onlyOwner {
    mintPrice = _mintPrice;
  }

  function setMintIsActive(bool _mintIsActive) external onlyOwner {
    mintIsActive = _mintIsActive;
  }

  function setMintLimit(uint16 _mintLimit) external onlyOwner {
    mintLimit = _mintLimit;
  }

  function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  function airDrop(address to, uint16 quantity) external onlyOwner {
    require(to != address(0), "invalid address");
    require(quantity > 0 && quantity <= tokensRemaining(), "invalid quantity");
    _safeMint(to, quantity);
  }
}