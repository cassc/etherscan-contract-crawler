// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CouchMinter is ERC721Enumerable, PaymentSplitter, Ownable {
  using Strings for uint256;
  
  uint256 public constant PRESALE_START = 1631797200;
  uint256 public constant SALE_START = 1631818800;

  uint256 public constant MAX_SUPPLY = 4444;
  uint256 public constant RESERVED_SUPPLY = 100;
  uint256 public constant NFT_PRICE = 0.025 ether;

  mapping(address => uint256) private _admintsRemaining;
  mapping(address => uint256) private _whitelisted;

  uint256 private _tokenIdCounter = 0;
  bool private _isActive = true;

  bool private _isBaseUriSet = false;
  string private _baseUri = "https://ipfs.io/ipfs/QmZ9MNgHqgPZNMdGiomY4Gmt9QKkm5aKn2nnpXgw97mC5z";

  event Mint(address _to, uint256 _amount);

  constructor(address[] memory payees, uint256[] memory shares) ERC721("Couches", "COUCH") PaymentSplitter(payees, shares) 
  { 
    for (uint i = 0; i < payees.length; i++) {
      _admintsRemaining[payees[i]] = 100;
    }
  }

  function isPresaleActive() public view returns (bool) {
    return block.timestamp >= PRESALE_START && block.timestamp < SALE_START && _isActive;
  }

  function isSaleActive() public view returns (bool) {
    return block.timestamp >= SALE_START && _isActive;
  }

  function addWhitelisted(address[] memory _addresses) public onlyOwner {
    for (uint i = 0; i < _addresses.length; i++) {
      _whitelisted[_addresses[i]] = 5;
    }
  }

  function isWhitelisted(address _address) view private returns (bool) {
    return _whitelisted[_address] > 0;
  }

  function getMaxAmount() public view returns (uint256) {
    if (isPresaleActive()) {
      return _whitelisted[msg.sender];
    } else if (isSaleActive()) {
      return 20;
    } else {
      return 0;
    }
  }

  function mint(uint256 amount) public payable {
    require(isSaleActive() || (isPresaleActive() && isWhitelisted(msg.sender)), "CouchMinter: sale is not active");
    require(amount * NFT_PRICE == msg.value, "CouchMinter: must send correct ETH amount");
    require(amount > 0, "CouchMinter: must mint more than 0");
    require(amount <= getMaxAmount(), string(abi.encodePacked("CouchMinter: must mint equal to or fewer than ", getMaxAmount().toString())));
    require(_tokenIdCounter < (MAX_SUPPLY - RESERVED_SUPPLY), "CouchMinter: sale has ended");
    require(_tokenIdCounter + amount <= (MAX_SUPPLY - RESERVED_SUPPLY), "CouchMinter: exceeds max supply");

    for (uint i = 0; i < amount; i++) {
      _tokenIdCounter = _tokenIdCounter + 1;
      _mint(msg.sender, _tokenIdCounter);
    }
    
    emit Mint(msg.sender, amount);

    if (isWhitelisted(msg.sender) && isPresaleActive()) {
      _whitelisted[msg.sender] = _whitelisted[msg.sender] - amount;
    }
  }

  function admint(uint256 amount) public {
    require(_admintsRemaining[msg.sender] > 0, "CouchMinter: message sender has no admints remaining");
    require(_admintsRemaining[msg.sender] - amount >= 0, "CouchMinter: exceeds number of admints remaining");
    require(amount > 0, "CouchMinter: must mint more than 0");
    require(_tokenIdCounter < MAX_SUPPLY, "CouchMinter: sale has ended");
    require(_tokenIdCounter + amount <= MAX_SUPPLY, "CouchMinter: exceeds max supply");

    for (uint i = 0; i < amount; i++) {
      _tokenIdCounter = _tokenIdCounter + 1;
      _mint(msg.sender, _tokenIdCounter);
    }
    
    emit Mint(msg.sender, amount);

    _admintsRemaining[msg.sender] = _admintsRemaining[msg.sender] - amount;
  }

  function toggleMinting() public onlyOwner {
    _isActive = !_isActive;
  }

  function setBaseURI(string memory baseUri) public onlyOwner {
    _isBaseUriSet = true;
    _baseUri = baseUri;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "CouchMinter: URI query for nonexistent token");

    string memory baseURI = _baseURI();

    if (!_isBaseUriSet) {
      return baseURI;
    }

    return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, _tokenId.toString()))
        : '';
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseUri;
  }

  function withdraw(address _target) public onlyOwner {
    payable(_target).transfer(address(this).balance);
  }
}