// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";


// ░█████╗░██████╗░████████╗  ████████╗░█████╗░██╗░░██╗██╗░░░██╗░█████╗░
// ██╔══██╗██╔══██╗╚══██╔══╝  ╚══██╔══╝██╔══██╗██║░██╔╝╚██╗░██╔╝██╔══██╗
// ███████║██████╔╝░░░██║░░░  ░░░██║░░░██║░░██║█████═╝░░╚████╔╝░██║░░██║
// ██╔══██║██╔══██╗░░░██║░░░  ░░░██║░░░██║░░██║██╔═██╗░░░╚██╔╝░░██║░░██║
// ██║░░██║██║░░██║░░░██║░░░  ░░░██║░░░╚█████╔╝██║░╚██╗░░░██║░░░╚█████╔╝
// ╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░  ░░░╚═╝░░░░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░░╚════╝░
// 
// ░██████╗░██╗░░░░░░█████╗░██████╗░░█████╗░██╗░░░░░
// ██╔════╝░██║░░░░░██╔══██╗██╔══██╗██╔══██╗██║░░░░░
// ██║░░██╗░██║░░░░░██║░░██║██████╦╝███████║██║░░░░░
// ██║░░╚██╗██║░░░░░██║░░██║██╔══██╗██╔══██║██║░░░░░
// ╚██████╔╝███████╗╚█████╔╝██████╦╝██║░░██║███████╗
// ░╚═════╝░╚══════╝░╚════╝░╚═════╝░╚═╝░░╚═╝╚══════╝

// @title Art Tokyo Global
// @author 0xjikangu
// @notice This is the Main NFT contract for Cotoh Tsumi project

contract ATGxCOTOHxSHiELD is ERC721AQueryable, Ownable, ReentrancyGuard, DefaultOperatorFilterer {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix;
  string public uriSuffix = ".json";
  string public projName;
  string public projDescription;
  string public projId;
  string public artistId;

  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public startDate;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;
  bool public dynamicStart = false;

// ATG Main Constructor
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _projName,
    string memory _projDescription,
    string memory _projId,
    string memory _artistId
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setProjName(_projName);
    setProjDescription(_projDescription);
    setProjId(_projId);
    setArtistId(_artistId);
  }

  /* Mint Compliance */
  // Requirement for mint to work
  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, "The whitelist sale is not enabled!");
    require(!whitelistClaimed[_msgSender()], "Address already claimed!");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  // Reserve tokens 
  function reserveTokens (address _receiver, uint256 _mintAmount) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    address to = _receiver;
    _safeMint(to, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  // Set Token Metadata Uri
  function tokenURI(uint256 _tokenId) public view virtual override (ERC721A, IERC721A) returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }
  
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  // Set Dutch Auction Date
  function setStartDate(uint256 _startDate) public onlyOwner {
    startDate = _startDate;
  }

  // Set Dutch Auction Start Date
  function setDynamicStart(bool _state) public onlyOwner {
    dynamicStart = _state;

    if (dynamicStart == true) {
      setStartDate(block.timestamp);
    }
  }

  // Get Dutch Auction Date
  function getStartDate() public view returns (uint256) {
    return startDate;
  }

  // Set Current Mint Price
  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  // Set Max Mint Amount
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  // Set Current Project Name
  function setProjName(string memory _projName) public onlyOwner {
    projName = _projName;
  }

  // Set Current Project Description
  function setProjDescription(string memory _projDescription) public onlyOwner {
    projDescription = _projDescription;
  }
  
  // Set Current Project Id
  function setProjId(string memory _projId) public onlyOwner {
    projId = _projId;
  }

  // Set Current Artist Id
  function setArtistId(string memory _artistId) public onlyOwner {
    artistId = _artistId;
  }

  // Set Token Uri Prefix
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  // Set Token Uri Suffix
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  // Set Contract Status
  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }
  // Set Whitelist Root Hash
  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  // Set Whitelist Status
  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  /* Opensea Operator Filter Registry */
  // Requirement for royalties in OS
  function transferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
      super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override (ERC721A, IERC721A)
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  // Fund Withdrawal
  function withdrawFund() external onlyOwner nonReentrant {

    (bool os, ) = payable(0xf31E2AbFe808718e17b9D602Ec7B01d5C06434c0).call{value: address(this).balance}("");
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}