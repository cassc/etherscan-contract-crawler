// SPDX-License-Identifier: MIT

/*
\____ \_/ __ \\____ \_/ __ \ 
|  |_> >  ___/|  |_> >  ___/ 
|   __/ \___  >   __/ \___  >
|__|        \/|__|        \/ 
because our devs are better than yours
*/

pragma solidity ^0.8.13;
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';

contract Pepe is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
  using Strings for uint256;

  bool public paused = true;
  bool public revealed = true;
  string public URI = 'ipfs://bafybeigkyc3t2rvarbhrwidy6sweqazo6sjqif5kyljxmlhuyg6a4aw76y/';
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public freeSupply = 2000;
  uint256 public freePerTx = 1;
  uint256 public freePerWallet = 1;
  uint256 public maxMintAmountPerTx;
  mapping(address => uint256) public walletLimits;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
  }

  modifier mintCondition(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Incorrect mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply reached!');

    if (msg.value < cost * _mintAmount) {
      require(freeSupply > 0, "Free mint is over");
      require(_mintAmount < freePerTx + 1, 'Too many free tokens per tx');
      require(walletLimits[msg.sender] + _mintAmount < freePerWallet + 1, 'You have used up your free mint allocation');
    } else {
      require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    }
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCondition(_mintAmount) {
    require(!paused, 'Sale is not live yet!');
    if (msg.value < cost * _mintAmount) {
      freeSupply -= _mintAmount;
      walletLimits[msg.sender] += _mintAmount;
    }
    _safeMint(_msgSender(), _mintAmount);
  }

  function treasuryAllocate(uint quantity) public onlyOwner {
    require(quantity > 0, "Wrong mint amount");
    require(totalSupply() + quantity <= maxSupply, "Max supply reached");
    _safeMint(msg.sender, quantity);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'URI query for nonexistent token');

    if (!revealed) {
      return _baseURI();
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
        : '';
  }

  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setFree(uint256 _amount) public onlyOwner {
    freeSupply = _amount;
  }

  function setfreePerWallet(uint256 _amount) public onlyOwner {
    freePerWallet = _amount;
  }

  function setfreePerTx(uint256 _amount) public onlyOwner {
    freePerTx = _amount;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setURI(string memory _URI) public onlyOwner {
    URI = _URI;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return URI;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
}