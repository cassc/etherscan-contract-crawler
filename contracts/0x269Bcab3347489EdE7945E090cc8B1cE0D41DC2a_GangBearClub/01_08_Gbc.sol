// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;


import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
contract GangBearClub is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;
  
  mapping (address => uint256) public WalletMint;
  string public baseURI="ipfs://QmfNiAfeMinFzzjbiUQyfLCcq8BAGMZtqF8N7QN4hnM8Rd/";
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  bool public freeMintpaused = false;
  bool public paused = true;
  uint public freeMint = 2;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxMintAmountPerTx
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost=0.00333 ether;
    maxSupply = 3333;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(WalletMint[msg.sender] <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount){
    require(_mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "FreeMint supply exceeded!");
    require(!freeMintpaused, 'The contract is paused!');
    if(WalletMint[msg.sender] < freeMint) 
        {
            if(_mintAmount < freeMint) _mintAmount = freeMint;
           require(msg.value >= (_mintAmount - freeMint) * cost,"Notice Cool Pudgy Bunnies:  Claim Free NFT");
            WalletMint[msg.sender] += _mintAmount;
           _safeMint(msg.sender, _mintAmount);
        }
        else
        {
           require(msg.value >= _mintAmount * cost,"Notice Cool Pudgy Bunnies:  Fund not enough");
            WalletMint[msg.sender] += _mintAmount;
           _safeMint(msg.sender, _mintAmount);
        }
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }
  
  function batchMint(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = baseURI;
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(),'.json'))
        : '';
  }
  
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
  }


  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

 function setFreeMintPaused(bool _state) public onlyOwner {
    freeMintpaused = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
}