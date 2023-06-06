// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract Museum is ERC721Enumerable, PaymentSplitter, Ownable {
  using Strings for uint256;

  string private _baseUri = "https://ipfs.io/ipfs/QmNWkSpsYAPjnWXbsZaCR6pq68SLYVRo1vM6nWbK3NKEVr/";
  mapping(uint256 => string) private _holidays;

  bool public _isMintingActive = true;

  uint256 public constant MAX_SUPPLY = 4801;
  uint256 public constant NFT_PRICE = 0.04 ether;
  uint256 public constant MAX_PER_PUBLIC_SALE = 2;
  uint256 private _admintsRemaining = 28;

  mapping(address => bool) private _admins;
  mapping(address => uint256) private _buyers; //key is buying address, value is number they've minted
  mapping(address => uint256) private _whitelist;

  uint256 public constant WHITELIST_A_START = 1633539600; // Oct 6 2021 1pm ET
  uint256 public constant WHITELIST_B_AND_C_START = 1633604400; // Oct 7 2021 7am ET
  uint256 public constant SALE_START = 1633626000; // Oct 7 2021 1pm ET

  uint8 public constant _SALE = 3;
  uint8 public constant _BC = 2;
  uint8 public constant _A = 1;

  uint256 private _mintCount = 0;
  uint256[MAX_SUPPLY] private _indices;

  event Mint(address _to, uint256 _amount);

  constructor(address[] memory payees, uint256[] memory shares) ERC721("Museum", "MUSE") PaymentSplitter(payees, shares) { 
    for(uint i = 0; i < payees.length; i++) {
      _admins[payees[i]] = true;
    }
  }

  function addWhitelisted(address[] memory _addresses) public onlyOwner {
    for (uint i = 0; i < _addresses.length; i++) {
      _whitelist[_addresses[i]] = 3;
    }
  }

  function isWhitelisted(address _address) view public returns (bool) {
    return _whitelist[_address] > 0;
  }

  function addHolidays(uint256[] memory starts, string[] memory baseUris) public onlyOwner {
    require(starts.length == baseUris.length, "Museum: array lengths must match");

    for (uint i = 0; i < starts.length; i++) {
      _holidays[starts[i]] = baseUris[i];
    }
  }

  function getSaleState() public view returns (uint8) {
    if (block.timestamp >= SALE_START) {
      return 3;
    } else if (block.timestamp >= WHITELIST_B_AND_C_START) {
      return 2;
    } else if (block.timestamp >= WHITELIST_A_START) {
      return 1;
    } else {
      return 0;
    }
  }

  function getMaxMints(uint8 saleState) public view returns (uint256) {
    if (saleState == _SALE) {
      return MAX_PER_PUBLIC_SALE - _buyers[msg.sender];
    } else if (saleState == 0) {
      return 0;
    }

    return _whitelist[msg.sender];
  }

  function mint(uint256 amount) public payable {
    uint8 saleState = getSaleState();
    require(_isMintingActive && saleState >= _A, "Museum: sale is not active");
    require(amount > 0, "Museum: must mint more than 0");
    require(amount <= getMaxMints(saleState), "Museum: minting too many");
    require(_mintCount < MAX_SUPPLY, "Museum: sale has ended");
    require(_mintCount + amount <= MAX_SUPPLY, "Museum: exceeds max supply");
    require(amount * NFT_PRICE == msg.value, "Museum: must send correct ETH amount");

    for (uint i = 0; i < amount; i++) {      
      uint256 randomID = getRandomIndex();
      _mintCount = _mintCount + 1;
      _mint(msg.sender, randomID);
    }
    
    if (isWhitelisted(msg.sender)) {
      _whitelist[msg.sender] = _whitelist[msg.sender] - amount;
    }

    if (saleState == _SALE) {
      _buyers[msg.sender] = _buyers[msg.sender] + amount;
    }

    emit Mint(msg.sender, amount);
  }

  function admint(address owner, uint256 amount) public onlyOwner {
    require(_admins[msg.sender], "Museum: must be admin to use");
    require(_admintsRemaining - amount >= 0, "Museum: Not enough admints remaining");
    require(amount > 0, "Museum: must mint more than 0");
    require(_mintCount < MAX_SUPPLY, "Museum: sale has ended");
    require(_mintCount + amount <= MAX_SUPPLY, "Museum: exceeds max supply");

    for (uint i = 0; i < amount; i++) {
      uint256 randomID = getRandomIndex();
      _mintCount = _mintCount + 1;
      _mint(owner, randomID);
    }
  }

  function getRandomIndex() private returns (uint256){
    uint256 remaining = MAX_SUPPLY - totalSupply();

    uint256 index = uint256(keccak256(abi.encodePacked(_mintCount, "museum", blockhash(block.number), block.timestamp, msg.sender, block.difficulty, gasleft()))) % remaining;

    uint256 randomIndex = 0;
    if (_indices[index] != 0) {
        randomIndex = _indices[index];
    } else {
        randomIndex = index;
    }

    if (_indices[remaining - 1] == 0) {
        _indices[index] = remaining - 1;
    } else {
        _indices[index] = _indices[remaining - 1];
    }   

    return randomIndex;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "Museum: URI query for nonexistent token");

    // get previous midnight from current time (GMT)
    uint256 midnight = block.timestamp - (block.timestamp % (60 * 60 * 24));
    string memory baseURI = _holidays[midnight];
    bytes memory baseURIBytes = bytes(baseURI);

    // get midnight of yesterday
    if (baseURIBytes.length == 0) {
      baseURI = _holidays[midnight - (60*60*24)];
    }

    baseURIBytes = bytes(baseURI);
    if (baseURIBytes.length == 0) {
      baseURI = _baseURI();
    }

    return string(abi.encodePacked(baseURI, tokenId.toString()));
  }

  function setBaseURI(string memory baseUri) public onlyOwner {
    _baseUri = baseUri;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseUri;
  }

  function toggleMinting() public onlyOwner {
    _isMintingActive = !_isMintingActive;
  }

  function withdraw(address _target) public onlyOwner {
    payable(_target).transfer(address(this).balance);
  }
}