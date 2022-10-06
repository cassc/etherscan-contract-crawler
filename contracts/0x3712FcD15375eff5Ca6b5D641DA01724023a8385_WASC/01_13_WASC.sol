// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract WASC is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  string public uriPrefix = 'ipfs://QmdXKn7Q4R2TtMgJzJzw93AFp4ZW3umawVyraQWg1SAQy9/';
  string public uriSuffix = '.json';
 
  uint256 public cost = 0.005 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmountPerTx = 30;
  uint256 public freeUntil = 10000;
  uint256 public freebiesPerWallet = 2;
  mapping(address => uint256) public freebieMap;

  bool public paused = true;

  constructor() ERC721A("WASC", "WASC") {
  }

  // 
  modifier mintCompliance(uint256 _mintAmount) {
    require(!paused, 'The contract is paused');
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require((totalSupply() + _mintAmount) <= maxSupply, 'Max supply exceeded!');
    _;
  }

  function mint(uint256 amount) public payable mintCompliance(amount) nonReentrant {
    uint256 freeMintsLeftForWallet = freebiesPerWallet - freebieMap[_msgSender()];
    uint256 freeMintsToBeUsed = amount < freeMintsLeftForWallet ? amount : freeMintsLeftForWallet;
    if (totalSupply() >= freeUntil) {
      freeMintsToBeUsed = 0;
    }
    uint256 payableAmount = amount - freeMintsToBeUsed;
    require(msg.value >= cost * payableAmount, 'Insufficient funds!');

    _safeMint(_msgSender(), amount);
    freebieMap[_msgSender()] += freeMintsToBeUsed;
  }

 	function reserve(address addr, uint256 amount) public onlyOwner {
	  require(totalSupply() + amount <= maxSupply, "Max supply exceeded");
    _safeMint(addr, amount);
  }

  //
  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned && ownership.addr != address(0)) {
        latestOwnerAddress = ownership.addr;
      }

      if (latestOwnerAddress == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setFreeUntil(uint256 _freeUntil) public onlyOwner {
    freeUntil = _freeUntil;
  }

  function setFreebiesPerWallet(uint256 _freebiesPerWallet) public onlyOwner {
    freebiesPerWallet = _freebiesPerWallet;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function decreaseSupply(uint256 supply) public onlyOwner {
    require(supply < maxSupply, "You are not allowed to increase supply");
    maxSupply = supply;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}