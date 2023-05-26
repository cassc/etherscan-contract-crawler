// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
   _____              _____    _    _   _____   _____    ______ 
  / ____|     /\     |  __ \  | |  | | |_   _| |  __ \  |  ____|
 | (___      /  \    | |__) | | |__| |   | |   | |__) | | |__   
  \___ \    / /\ \   |  ___/  |  __  |   | |   |  _  /  |  __|  
  ____) |  / ____ \  | |      | |  | |  _| |_  | | \ \  | |____ 
 |_____/  /_/    \_\ |_|      |_|  |_| |_____| |_|  \_\ |______|
 
 */

contract Saphire is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistMintClaimed;
  mapping(address => bool) private _approvedMarketplaces;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  
  bool public publicMintEnabled = false;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;
  

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _hiddenMetadataUri,
    uint256 _cost,
    uint256 _maxSupply
  ) ERC721A(_tokenName, _tokenSymbol){
    setCost(_cost);
    maxSupply = _maxSupply;
    setHiddenMetadataUri(_hiddenMetadataUri);
  }


  modifier publicMintCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    require(totalSupply() + _mintAmount <= 77, "Public mint supply exceeded!");
    _;
  }

  modifier whitelistMintCompliance(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable whitelistMintCompliance(_mintAmount) {
    // Verify whitelistmint requirements
    require(_mintAmount == 1, "You can mint only 1!");
    require(whitelistMintEnabled, "The whitelist mint is not enabled!");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");
    require(!whitelistMintClaimed[_msgSender()], "Address already claimed!");
    
    whitelistMintClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

 function internalMint(uint256 _teamAmount) external onlyOwner  {
    require(totalSupply() + _teamAmount <= maxSupply, "Max supply exceeded!");
    _safeMint(_msgSender(), _teamAmount);
  }

  function publicMint(uint256 _mintAmount) public payable publicMintCompliance(_mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= 3, "You can mint from 1 to 3!");
    require(publicMintEnabled, "The public mint is not enabled!");
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }


  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPublicMintEnabled(bool _state) public onlyOwner {
    publicMintEnabled = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
      uint256 balance = address(this).balance;
        (bool c1, ) = payable(0x818D5B4Ee0a4D653218Ecd4c131b32A7F983Fa52).call{value: balance * 15 / 100}('');
        require(c1);
        (bool c2, ) = payable(0x81794754b0E4c1463513D996794b600F358e6b1C).call{value: balance * 85 / 100}('');
        require(c2);
    }
    

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function approve(address to, uint256 tokenId) public virtual override {
    require(_approvedMarketplaces[to], "Invalid marketplace");
    super.approve(to, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) public virtual override {
    require(_approvedMarketplaces[operator], "Invalid marketplace");
    super.setApprovalForAll(operator, approved);
  }

  function setApprovedMarketplace(address market, bool approved) public onlyOwner {
    _approvedMarketplaces[market] = approved;
  }
}