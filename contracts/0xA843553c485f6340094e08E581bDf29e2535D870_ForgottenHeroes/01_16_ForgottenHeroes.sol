// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract ForgottenHeroes is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  mapping(address => uint256) public freeClaimed;

  string public uriPrefix = 'ipfs://QmdvN51XWmknf9gxZGjkakJT5Xq5zZMdRBaaFo3twXJfD4/';
  string public uriSuffix = '.json';
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public freeSupply = 2000;
  uint256 public freePerWallet = 1;
  uint256 public maxMintAmountPerTx;
  address public theOwner = 0x27F1310104f1051c6Fa3c105517380e9Eda8ed46;

  bool public paused = false;

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

  function mint(uint256 _mintAmount) external payable {
    require(!paused, "The contract is paused!");
    require(totalSupply() + _mintAmount < maxSupply + 1, "No more left to mint!");

    if(freeSupply - _mintAmount < 0){
      require(msg.value >= (cost * _mintAmount), "Incorrect ETH value sent");
    } else {
        if (balanceOf(msg.sender) + _mintAmount > freePerWallet) {
          if (msg.sender != theOwner) {
              require((cost * _mintAmount) <= msg.value, "Incorrect ETH value sent");
          }
        require(_mintAmount < maxMintAmountPerTx + 1, "Max mints per transaction exceeded");
        } else {
            require(_mintAmount < freePerWallet + 1, "Max free mints per transaction exceeded");
            freeSupply -= _mintAmount;
        }
    }
    _safeMint(msg.sender, _mintAmount);
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

  function setFree(uint256 _amount) public onlyOwner {
    freeSupply = _amount;
  }

  function setFreePerWallet(uint256 _amount) public onlyOwner {
    freePerWallet = _amount;
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

  function treasuryMint(uint _amount) public onlyOwner {
    require(_amount > 0, "Invalid mint amount");
    require(totalSupply() + _amount <= maxSupply, "Maximum supply exceeded");
    _safeMint(msg.sender, _amount);
  }
  
  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}