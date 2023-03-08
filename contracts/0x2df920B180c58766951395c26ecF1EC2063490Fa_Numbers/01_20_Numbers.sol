// SPDX-License-Identifier: MIT

/*********************************      
 numbers on chain : the initiation     
 *********************************/

pragma solidity ^0.8.13;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./INumbersDescriptor.sol";

contract Numbers is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {

  using Strings for uint256;
  mapping(address => uint256) public freeClaimed;
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public freeSupply = 0;
  uint256 public freePerTx = 1;
  uint256 public freePerWallet = 1111;
  uint256 public maxMintAmountPerTx;

  bool public paused = false;
  bool public revealed = true;

  // Seed
  event SeedUpdated(uint256 indexed tokenId, uint256 seed);
  mapping(uint256 => uint256) internal seeds;
  INumbersDescriptor public descriptor;
  bool public canUpdateSeed = true;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    INumbersDescriptor newDescriptor
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    descriptor = newDescriptor;
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
    uint256 nextTokenId = totalSupply();
    for (uint32 i; i < _mintAmount;) {
            seeds[nextTokenId + 1] = generateSeed(nextTokenId + 1);
            _safeMint(_msgSender(), 1);
            unchecked { ++nextTokenId; ++i; }
    }
  }

  function teamMint(uint quantity) public onlyOwner {
    require(quantity > 0, "Invalid mint amount");
    require(totalSupply() + quantity <= maxSupply, "Maximum supply exceeded");

    uint256 nextTokenId = totalSupply();
    for (uint32 i; i < quantity;) {
            seeds[nextTokenId + 1] = generateSeed(nextTokenId + 1);
            _safeMint(_msgSender(), 1);
            unchecked { ++nextTokenId; ++i; }
    }
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function setDescriptor(INumbersDescriptor newDescriptor) external onlyOwner {
        descriptor = newDescriptor;
  }

  function updateSeed(uint256 tokenId, uint256 seed) external onlyOwner {
        require(canUpdateSeed, "Cannot set the seed");
        seeds[tokenId] = seed;
        emit SeedUpdated(tokenId, seed);
  }

    function disableSeedUpdate() external onlyOwner {
        canUpdateSeed = false;
  }

  function tokenURI(uint256 tokenId) public view override returns(string memory) {
        require(_exists(tokenId), "Numbers does not exist.");
        uint256 seed = seeds[tokenId];
        return descriptor.tokenURI(tokenId, seed);
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

  function getSeed(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Numbers does not exist.");
        return seeds[tokenId];
    }

  function randoNumbers(uint64 input, uint64 min, uint64 max) internal pure returns (uint64) {
    uint64 rRange = max - min;
    return max - (uint64(uint(keccak256(abi.encodePacked(input + 2023)))) % rRange) - 1;
  }

  function generateSeed(uint256 tokenId) private view returns (uint256) {
        uint256 r = randomize(tokenId);
        uint256 topSeed = 100 * (r % 7 + 10) + ((r >> 48) % 20 + 10);
        uint256 indexSeed = 100 * ((r >> 96) % 6 + 10) + ((r >> 96) % 20 + 10);
        uint256 bodySeed = 100 * ((r >> 144) % 7 + 10) + ((r >> 144) % 20 + 10);
        uint256 footerSeed = 100 * ((r >> 192) % 2 + 10) + ((r >> 192) % 20 + 10);
        return 10000 * (10000 * (10000 * topSeed + indexSeed) + bodySeed) + footerSeed;
    }

    function randomize(uint256 tokenId) private view returns (uint256 pseudoRandomness) {
        pseudoRandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId))
        );

        return pseudoRandomness;
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