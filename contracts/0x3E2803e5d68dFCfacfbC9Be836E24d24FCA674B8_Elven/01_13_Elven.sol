// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Elven is ERC721Enumerable, Ownable {
  uint256 private basePrice = 25000000000000000; //0.025

  uint256 private reserveAtATime = 25;
  uint256 private reservedCount = 0;
  uint256 private maxReserveCount = 100;
  address private MPAddress = 0xAa0D34B3Ac6420B769DDe4783bB1a95F157ddDF5;
  address private ARAddress = 0xfdA4Be6dc1Be74010B768556CD28C330a6Ad23F9;
  address private RexAuth = 0x2fea18841E5846f1A827DC3d986F76B6773bdf45;

  string _baseTokenURI;
  bool public isActive = false;
  bool public isAllowListActive = false;
  bool public isFreeListActive = false;
  uint256 public constant MAX_MINTSUPPLY = 6000;
  uint256 public maximumAllowedTokensPerPurchase = 25;
  uint256 public allowListMaxMint = 10;
  uint256 public freeListMaxMint = 2;
  mapping(address => bool) private _allowList;
  mapping(address => bool) private _freeList;
  mapping(address => uint256) private _allowListClaimed;
  mapping(address => uint256) private _freeListClaimed;

  constructor(string memory baseURI) ERC721("ELVEN", "ELVN") {
      setBaseURI(baseURI);
  }

  modifier saleIsOpen {
      require(totalSupply() <= MAX_MINTSUPPLY, "Sale ended.");
      _;
  }

  modifier onlyAuthorized() {
      require(MPAddress == msg.sender || owner() == msg.sender || RexAuth == msg.sender);
      _;
  }

  function setMaximumAllowedTokens(uint256 _count) public onlyAuthorized {
      maximumAllowedTokensPerPurchase = _count;
  }

  function setReserveAtATime(uint256 val) public onlyAuthorized {
      reserveAtATime = val;
  }
  
  function setBaseURI(string memory baseURI) public onlyAuthorized {
      _baseTokenURI = baseURI;
  }

  function setActive(bool val) public onlyAuthorized {
    isActive = val;
  }

  function setIsAllowListActive(bool _isAllowListActive) external onlyAuthorized {
    isAllowListActive = _isAllowListActive;
  }

  function setIsFreeListActive(bool _isFreeListActive) external onlyAuthorized {
    isFreeListActive = _isFreeListActive;
  }

  function getTotalSupply() external view returns (uint256) {
      return totalSupply();
  }

  function addToAllowList(address[] calldata addresses) external onlyAuthorized {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add a null address");

      _allowList[addresses[i]] = true;
      _allowListClaimed[addresses[i]] > 0 ? _allowListClaimed[addresses[i]] : 0;
    }
  }

  function addToFreeList(address[] calldata addresses) external onlyAuthorized {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add a null address");

      _freeList[addresses[i]] = true;
      _freeListClaimed[addresses[i]] > 0 ? _freeListClaimed[addresses[i]] : 0;
    }
  }

  function checkIfOnAllowList(address addr) external view returns (bool) {
    return _allowList[addr];
  }

  function checkIfOnFreeList(address addr) external view returns (bool) {
    return _freeList[addr];
  }

  function removeFromAllowList(address[] calldata addresses) external onlyAuthorized {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add a null address");

      _allowList[addresses[i]] = false;
    }
  }

  function removeFromFreeList(address[] calldata addresses) external onlyAuthorized {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add a null address");

      _freeList[addresses[i]] = false;
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
  }

  function reserveNft() public onlyAuthorized {
      require(reservedCount <= maxReserveCount, "All Reserves Taken");
      uint256 supply = totalSupply();
      uint256 i;
      for (i = 0; i < reserveAtATime; i++) {
          _safeMint(msg.sender, supply + i);
          reservedCount++;
      }  
  }

  function mint(address _to, uint256 _count) public payable saleIsOpen {
      if (msg.sender != owner()) {
          require(isActive, "Sale not active");
      }
      require(totalSupply() + _count <= MAX_MINTSUPPLY, "Total supply exceeded.");
      require(
          _count <= maximumAllowedTokensPerPurchase,
          "Above purchase limit"
      );
      require(msg.value >= basePrice * _count, "Not Enough ETH");

      for (uint256 i = 0; i < _count; i++) {
          _safeMint(_to, totalSupply());
      }
  }

  function preSaleMint(uint256 _count) public payable saleIsOpen {
    require(isAllowListActive, 'presale not active');
    require(_allowList[msg.sender], 'Not on Allow List');
    require(_count <= allowListMaxMint, 'Above Purchase Limit');
    require(_allowListClaimed[msg.sender] + _count <= allowListMaxMint, 'exceededs allowed total');
    require(msg.value >= basePrice * _count, 'Not Enough ETH');

    for (uint256 i = 0; i < _count; i++) {
      _allowListClaimed[msg.sender] += 1;
      _safeMint(msg.sender, totalSupply());
    }
  }

  function ogFreeMint() public payable saleIsOpen {
    require(isFreeListActive, 'og not active');
    require(_freeList[msg.sender], 'Not on Free List');
    require(_freeListClaimed[msg.sender] + 1 <= freeListMaxMint, 'exceededs allowed total');

    _freeListClaimed[msg.sender] += 1;
    _safeMint(msg.sender, totalSupply());
  }

  function walletOfOwner(address _owner) external view returns(uint256[] memory) {
    uint tokenCount = balanceOf(_owner);
    uint256[] memory tokensId = new uint256[](tokenCount);
    for(uint i = 0; i < tokenCount; i++){
        tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }

  function withdraw() external onlyAuthorized {
    uint balance = address(this).balance;
    payable(MPAddress).transfer(balance * 2500 / 10000);
    payable(ARAddress).transfer(balance * 2500 / 10000);
    payable(owner()).transfer(address(this).balance);
  }
}