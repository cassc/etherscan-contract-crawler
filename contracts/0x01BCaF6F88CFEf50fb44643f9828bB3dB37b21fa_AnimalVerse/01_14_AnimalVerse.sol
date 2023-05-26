// SPDX-License-Identifier: MIT

// Update 22 June : Upgrade logic of WL mint time before public sale

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AnimalVerse is ERC721, Ownable, ReentrancyGuard {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;
  Counters.Counter private supplyLegend;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  uint256 public maxSupply = 10000;
  uint256 public legendMaxSupply = 8;
  uint256 public cost = 0.02 ether;   
  uint256 public costLegend = 1 ether; 
  uint256 public maxMintAmountPerTx = 3;
  uint256 public maxNFTPerAccount = 3;
  uint256 public maxFreeMint = 5200;
  uint256 public whitelistEndDate = 1657965600;

  mapping(address => uint256) public addressMintedBalance;
  mapping(address => uint256) public addressGetFreeMint;
  bytes32 public whitelistMerkleRoot;
  address private founder = 0x04ae8CA7B2592Bb65eb1bA489383336841507B0D;

  bool public ALpaused = true;
  bool public revealed = false;

  constructor() ERC721("Animalverse Dancing Underwater", "ADU") {
    setHiddenMetadataUri("ipfs://QmcZHPWn9REq8TNeM1ALNJtPNLXb5K17iLNkpqYGdQXumk/hidden.json");
    for (uint256 i = 0; i <= 7; i++) {
      supply.increment();  // Shift supply to 8
    }
  }

// Modifier 
  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, 'max NFT limit exceeded!');
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function totalSupplyLegend() public view returns (uint256) {
    return supplyLegend.current();
  }

  function mint(uint256 _mintAmount , bytes32[] calldata merkleProof) 
    public 
    payable 
    mintCompliance(_mintAmount)
    nonReentrant 
  {
    require(!ALpaused, "The contract is paused!");
    uint256 ownerMintedCount = addressMintedBalance[msg.sender];

    if(block.timestamp < whitelistEndDate) {
      require(isValidMerkleProof(merkleProof, whitelistMerkleRoot), "This is Whitelist round - you are not whitelisted.");
    }
      
    require(
      ownerMintedCount + _mintAmount <= maxNFTPerAccount,
      "Max NFT per address exceeded."
    );
    require(msg.value >= getCurrentPrice(_mintAmount, merkleProof), "Insufficient funds.");
    require(
      _mintAmount <= maxMintAmountPerTx,
      "Max mint amount per transaction exceeded."
    );

    if (addressGetFreeMint[_msgSender()] == 0){
        if(maxFreeMint == 0){
            maxFreeMint = 0;
        }else{
            maxFreeMint = maxFreeMint - 1;
            addressGetFreeMint[_msgSender()] = addressGetFreeMint[_msgSender()] + 1;
        }  
    }

    _mintLoop(msg.sender, _mintAmount);

    (bool cl, ) = payable(founder).call{value: msg.value}("");
    require(cl);
  }

  function mintLegend(uint256 _mintAmount) 
    public 
    payable 
    nonReentrant 
  {
    require(!ALpaused, "The contract is paused!");
    uint256 ownerMintedCount = addressMintedBalance[msg.sender];
    require(supplyLegend.current() + _mintAmount <= legendMaxSupply, 'Legend : max NFT limit exceeded!');
    require(
      ownerMintedCount + _mintAmount <= maxNFTPerAccount,
      "Max NFT per address exceeded."
    );
    require(msg.value >= costLegend * _mintAmount, "Legend : insufficient funds.");
    require(
      _mintAmount <= maxMintAmountPerTx,
      "Max mint amount per transaction exceeded."
    );

    _mintLegend(msg.sender, _mintAmount);

    (bool cl, ) = payable(founder).call{value: msg.value}("");
    require(cl);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  function burn(uint256 tokenId) public { 
     require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
  }

  function getCurrentPrice(uint256 _mintAmount, bytes32[] calldata merkleProof) public view returns (uint256) {
    uint256 finalPrice;
    if(block.timestamp < whitelistEndDate) {
      if(isValidMerkleProof(merkleProof,whitelistMerkleRoot) && addressGetFreeMint[_msgSender()] == 0 && maxFreeMint > 0){
          finalPrice = (_mintAmount - 1) * cost;
          return finalPrice;
        } else {
          finalPrice = _mintAmount * cost;
          return finalPrice;
        }
    } else if (addressGetFreeMint[_msgSender()] == 0 && maxFreeMint > 0) {
      finalPrice = (_mintAmount - 1) * cost;
      return finalPrice;
    } else {
      finalPrice = _mintAmount * cost;
          return finalPrice;
    }
  }

  function isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) private view returns (bool) {
        if(MerkleProof.verify(merkleProof,root,keccak256(abi.encodePacked(msg.sender)))){
          return true;
        }else{
          return false;
        }           
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;
  
    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= supply.current()) {
      if (_exists(currentTokenId)) {
        address currentTokenOwner = ownerOf(currentTokenId);

        if (currentTokenOwner == _owner) {
          ownedTokenIds[ownedTokenIndex] = currentTokenId;

          ownedTokenIndex++;
        }
      } 
      
      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

// SETTING parameter

  function setPresaleEndDate(uint256 _date) public onlyOwner {
    whitelistEndDate = _date;
  }

  function setRevealed(bool _state) external onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) external onlyOwner {
    cost = _cost;
  }

  function setLGCost(uint256 _cost) external onlyOwner {
    costLegend = _cost;
  }

  function setMaxFreeMint(uint256 _max) external onlyOwner {
    maxFreeMint = _max;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) external onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMaxNFTPerAccount(uint256 _maxNFT) external onlyOwner {
    maxNFTPerAccount = _maxNFT;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) external onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) external onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setALPaused(bool _state) external onlyOwner {
    ALpaused = _state;
  }

  function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      addressMintedBalance[_receiver]++;
      _safeMint(_receiver, supply.current());
    }
  }

  function _mintLegend(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supplyLegend.increment();
      addressMintedBalance[_receiver]++;
      _safeMint(_receiver, supplyLegend.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}