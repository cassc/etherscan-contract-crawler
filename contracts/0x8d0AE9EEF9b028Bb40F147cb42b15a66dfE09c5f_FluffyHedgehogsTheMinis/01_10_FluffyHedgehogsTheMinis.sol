// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FluffyHedgehogsTheMinis is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => uint256) public addressPresaleMintedBalance;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;

  uint256 public price = 0.02 ether;
  uint256 public maxSupply = 1000;
  uint256 public maxMintAmountPerTx = 2;
  uint256 public addressLimitPresale = 2;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor() ERC721A("FluffyHedgehogsTheMinis", "FHTM") {
    setHiddenMetadataUri("https://files.fluffyhedgehogs.com/hidden.json");
  }

// Check one
  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0, "Lol, cannot mint zero hedgies");
    require(_mintAmount <= maxMintAmountPerTx, "Oh no, cannot mint that many hedgies!");
    require(totalSupply() + _mintAmount <= maxSupply, "Maximum supply of hedgies exceeded!");
    _;
  }

// Check two
  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= price * _mintAmount, "You need more Ether in your wallet!");
    _;
  }

// Function whitelist mint
  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, "Whitelist mint is not enabled!");
    uint256 ownerMintedCount = addressPresaleMintedBalance[_msgSender()];
    require(ownerMintedCount + _mintAmount <= addressLimitPresale, "Maximum hedgies per address during whitelist exceeded");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid merkleproof, ask Fluffy!");

    addressPresaleMintedBalance[_msgSender()] += _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }

// Function regular mint
  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, "Minting is not possible at the moment!");

   _safeMint(_msgSender(), _mintAmount);
  }

// Check owner mint
  modifier mintComplianceOwner(uint256 _mintAmount) {
    require(_mintAmount > 0, "Lol, cannot mint zero hedgies");
    require(totalSupply() + _mintAmount <= maxSupply, "Maximum of hedgies exceeded!");
    _;
  }

// Function only owner mint
  function mintForAddress(uint256 _mintAmount, address _to) public mintComplianceOwner(_mintAmount) onlyOwner {
   _safeMint(_to, _mintAmount);
  }

// Let's start with number one
  function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

// Metadata things
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

// Switch button reveal
  function switchRevealed() public onlyOwner {
    revealed = !revealed;
  }

// Function for changing the mintprice
  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  // Function for setting a new maximum whitelist mint amount per transaction
  function setAddressLimitPresale(uint256 _newAddressLimitPresale) public onlyOwner {
   addressLimitPresale = _newAddressLimitPresale;
 }

 // Function for setting a new maximum mint amount per transaction
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  // Function for setting a new hidden metadata URI
  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  // Function for setting a new URI prefix
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  // Function for setting a new URI suffix
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  // Switch button pauze
  function switchPaused() public onlyOwner {
    paused = !paused;
  }

// Function for setting a new merkleroot
  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  // Switch button whitelist mint
  function switchWhitelistMintEnabled() public onlyOwner {
    whitelistMintEnabled = !whitelistMintEnabled;
  }

  // Withdraw function for owner
  function withdraw() public onlyOwner nonReentrant {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success);
  }

  // returning the URI
  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  // Update the value for addressPresaleMintedBalance
  function setPresaleMintedBalance(address _addr, uint _i) public onlyOwner {
    addressPresaleMintedBalance[_addr] = _i;
  }

// Reset the value for addressPresaleMintedBalance
  function removePresaleMintedBalance(address _addr) public onlyOwner {
    delete addressPresaleMintedBalance[_addr];
  }
}