// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;


import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
contract DGKingdom is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

 // bytes32 public merkleRoot;

  string public baseURI;
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public freeMintSupply;
  uint256 public maxMintAmountPerTx;
  bool public freeMintpaused = false;
  bool public paused = true;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxMintAmountPerTx,
    string memory _newBaseURI
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost=0.0333 ether;
    maxSupply = 3333;
    freeMintSupply=1111;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setBaseURI(_newBaseURI);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _;
  }

  function freeMint(uint256 _mintAmount) public payable {
    require(_mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= freeMintSupply, "FreeMint supply exceeded!");
    require(!freeMintpaused, 'The contract is paused!');
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    _safeMint(_msgSender(), _mintAmount);
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
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString()))
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