// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract WarWolvesArmy is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  
  Counters.Counter private supply;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  
  uint256 public cost = 0 ether;
  uint256 public finalMaxSupply = 10000;
  uint256 public currentMaxSupply = 999;
  uint256 public maxMintAmountPerTx = 50;

  bool public paused = true; // Set this so that sale status is not opened when the contract is deployed
  bool public whitelistMintEnabled = false;

  constructor(
      string memory _tokenName,
      string memory _tokenSymbol,
      uint256 _cost,
      uint256 _maxSupply
    ) ERC721(_tokenName, _tokenSymbol) {
      setCost(_cost);
      currentMaxSupply = _maxSupply;
    }

  modifier mintCompliance(uint256 _mintAmount) {
    require(supply.current() + _mintAmount <= currentMaxSupply, "Sorry, there's not that many War Wolves left.");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, "The whitelist sale is not enabled!");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");
    
    whitelistClaimed[msg.sender] = true;
    _mintLoop(msg.sender, _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount){
    require(!paused, "The contract is paused!");
    
    uint256 mintPrice = cost * _mintAmount;
    
    // refund if customer paid more than the cost to mint
    if (msg.value > mintPrice) {
      Address.sendValue(payable(msg.sender), msg.value - mintPrice);
    }

    _mintLoop(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  function mintForOwner(uint256 _mintAmount) public mintCompliance(_mintAmount) onlyOwner {
    require(!paused, "The contract is paused!");
    require(_mintAmount > 0);
    
    _mintLoop(msg.sender, _mintAmount);
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

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= currentMaxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
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

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }
 
  // Update the cost per mint in wei
  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function resetFinalMaxSupply() public onlyOwner {
    // Now finalized that no more tokens are required.  
    finalMaxSupply = currentMaxSupply;
  }

  function setCurrentMaxSupply(uint256 _currentMaxSupply) public onlyOwner {
      // Check current supply should not be more then final max supply & greater then the already minted supply
    require(_currentMaxSupply <= finalMaxSupply && _currentMaxSupply >= totalSupply(), "Current Max supply exceeds final supply or lower then total supply");
    currentMaxSupply = _currentMaxSupply;
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

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}