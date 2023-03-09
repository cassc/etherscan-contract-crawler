// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract GeetcoinPresents is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {

  using Strings for uint256;
  mapping(address => uint256) public freeClaimed;
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public freeSupply = 1000;
  uint256 public freePerTx = 1;
  uint256 public freePerWallet = 1;
  uint256 public maxMintAmountPerTx;

  bool public paused = false;
  bool public revealed = true;
  string public uriPrefix = 'ipfs://QmbM2qBG23KGnnmCxUDiANLTKCmEQQWuwXFT1emYXqLn16/';
  string public uriSuffix = '.json';

  // chromatic fusion
  mapping(uint64 => uint64) baseColor;
  mapping(uint64 => uint64) morphColor;
  bool public isFusable = false;

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

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');

    if (msg.value < cost * _mintAmount) {
      require(freeSupply > 0, "Free supply is depleted");
      require(_mintAmount < freePerTx + 1, 'Too many free tokens at a time');
      require(freeClaimed[msg.sender] + _mintAmount < freePerWallet + 1, 'Too many free tokens claimed');
    } else {
      require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    }
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    require(tx.origin == msg.sender, "Contracts not allowed to mint.");
    if (msg.value < cost * _mintAmount) {
      freeSupply -= _mintAmount;
      freeClaimed[msg.sender] += _mintAmount;
    }
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function teamMint(uint quantity) public onlyOwner {
    require(quantity > 0, "Invalid mint amount");
    require(totalSupply() + quantity <= maxSupply, "Maximum supply exceeded");
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
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setFree(uint256 _amount) public onlyOwner {
    freeSupply = _amount;
  }

  function setFreePerWallet(uint256 _amount) public onlyOwner {
    freePerWallet = _amount;
  }

  function setFreePerTx(uint256 _amount) public onlyOwner {
    freePerTx = _amount;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
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

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function uint64Initalize(uint256 _amount) public onlyOwner {
    maxSupply = _amount;
  }
  
  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function toggleFuse() public onlyOwner {
        isFusable = !isFusable;
  }

  function fuse(uint64[] memory tokens) public {
        require(isFusable, "combining not active");
        uint64 sum;
        for (uint i = 0; i < tokens.length; i++) {
            require(ownerOf(tokens[i]) == msg.sender, "must own all tokens");
            sum = sum + getGeetcoinPresents(tokens[i]);
        }
        if (sum > 1000) {
            revert("sum must be under 1000");
        }
        for (uint64 i = 1; i < tokens.length; i++) {
            _burn(tokens[i]);
            morphColor[tokens[i]] = 0;
            baseColor[tokens[i]] = 0;
        }

        morphColor[tokens[0]] = sum;
        baseColor[tokens[0]] = randGeetcoinPresents(tokens[0], 1, 4);
  }

  function getGeetcoinPresents(uint64 tokenId) public view returns (uint64) {
        if (!_exists(tokenId)) {
            return 0;
        } else if (morphColor[tokenId] > 0) {
            return morphColor[tokenId];
        } else {
            return tokenId;
        }
    }

  function randGeetcoinPresents(uint64 input, uint64 min, uint64 max) internal pure returns (uint64) {
    uint64 rRange = max - min;
    return max - (uint64(uint(keccak256(abi.encodePacked(input + 2023)))) % rRange) - 1;
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
}