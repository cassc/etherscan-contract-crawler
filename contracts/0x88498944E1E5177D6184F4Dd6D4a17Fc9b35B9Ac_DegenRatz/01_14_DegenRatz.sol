// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract DegenRatz is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  string public uriPrefix = '';
  uint256 public mintPrice = 0.005 ether;
  uint256 public maxSupply;
  uint256 public maxAllowedTokensPerPurchase = 3;
  uint256 public maxAllowedTokensPerWallet = 3;
  mapping(address => uint) private _numberOfMints;

  bool public paused = true;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol
  ) ERC721A(_tokenName, _tokenSymbol) {
  }

  modifier saleIsOpen {
    require(totalSupply() <= maxSupply, "Sale has ended.");
    _;
  }

  function togglePaused() public onlyOwner {
    paused = !paused;
  }

  function mint(uint256 _mintAmount) public payable saleIsOpen {
    
		require(!paused, 'Sales are off');
		require(_mintAmount <= maxAllowedTokensPerPurchase,'Amount is past transaction limit');
		require(_totalMinted() + _mintAmount <= maxSupply,'Amount is higher than max supply');
    require(_numberOfMints[msg.sender] + _mintAmount <= maxAllowedTokensPerWallet,'Amount is higher than the max per wallet limit');

    uint paidMintAmount = _mintAmount;
    uint alreadyMinted = _numberOfMints[msg.sender];
    
    if(alreadyMinted < 1) {
        uint freeMintsLeft = 1 - alreadyMinted;
        if(_mintAmount > freeMintsLeft) {
            paidMintAmount = _mintAmount - freeMintsLeft;
        }
        else {
            paidMintAmount = 0;
        }
    }
		require(
			msg.value >= paidMintAmount * mintPrice,
			'Not Enough Ether in account to buy'
		);
		_numberOfMints[msg.sender] += _mintAmount;
		_safeMint(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ''))
        : '';
  }

  function setCost(uint256 _price) public onlyOwner {
    mintPrice = _price;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function getReserves() public onlyOwner {
    require(totalSupply() == 0, "All supply finished");
    _safeMint(msg.sender, 300);
  }

  function setMaximumAllowedTokensPerTx(uint256 _count) public onlyOwner {
    maxAllowedTokensPerPurchase = _count;
  }
  
  function setMaximumAllowedTokensPerWallet(uint256 _count) public onlyOwner {
    maxAllowedTokensPerWallet = _count;
  }

  function setMaxMintSupply(uint256 maxMintSupply) public onlyOwner {
    maxSupply = maxMintSupply;
  }

    function howManyMints(address owner) external view returns (uint) {
        return _numberOfMints[owner];
    }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}