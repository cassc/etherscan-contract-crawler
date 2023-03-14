// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';

contract TwelveCubes is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
  using Strings for uint256;

  // Mint States
  bool public paused = true;
  bool public revealed = true;

  // Metadata
  string public prefixURI = 'ipfs://QmRSrhyvLFbru4R86ScDU94yyScga8XtjbFYH7p53wFftv/';
  string public fileFormat = '.json';
  
  // Mint Info
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public freeRemaining = 400;
  uint256 public freePerTx = 1;
  uint256 public freePerWallet = 1;
  uint256 public maxMintAmountPerTx;

  // Wallet Constraints
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

  modifier mintCheck(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');

    if (msg.value < cost * _mintAmount) {
      require(freeRemaining > 0, "Free supply is over");
      require(_mintAmount < freePerTx + 1, 'You are minting too many free tokens per tx');
      require(walletLimits[msg.sender] + _mintAmount < freePerWallet + 1, 'You have minted your free token allocation');
    } else {
      require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    }
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCheck(_mintAmount) {
    require(!paused, 'The contract is paused!');
    require(tx.origin == msg.sender, "Contracts not allowed to mint.");
    if (msg.value < cost * _mintAmount) {
      freeRemaining -= _mintAmount;
      walletLimits[msg.sender] += _mintAmount;
    }
    _safeMint(_msgSender(), _mintAmount);
  }

  function treasuryAllocate(uint quantity) public onlyOwner {
    require(quantity > 0, "Wrong mint amount");
    require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");
    _safeMint(msg.sender, quantity);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (!revealed) {
      return _baseURI();
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), fileFormat))
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

  function mintForPromise(uint256 _mintAmount, address _receiver) public onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setFree(uint256 _amount) public onlyOwner {
    freeRemaining = _amount;
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

  function setprefixURI(string memory _prefixURI) public onlyOwner {
    prefixURI = _prefixURI;
  }

  function setfileFormat(string memory _fileFormat) public onlyOwner {
    fileFormat = _fileFormat;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return prefixURI;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
}