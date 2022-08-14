// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract HawaOriginNFT is ERC721A, Ownable, ReentrancyGuard {
  bytes32 public merkleRoot;
  mapping(address => uint256) public staffMintClaimed;
  mapping(address => uint256) public vipMintClaimed;
  mapping(address => uint256) public whitelistMintClaimed;
  mapping(address => uint256) public publicMintClaimed;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxMintBatchSize;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerWallet;
  uint256 public maxAmountForTeamsReserve = 100;

  bool public paused = true;
  bool public staffMintEnabled = false;
  bool public vipMintEnabled = false;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxBatchSize,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerWallet,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol, _maxBatchSize, _maxSupply) {
    cost = _cost;
    maxMintBatchSize = _maxBatchSize;
    maxSupply = _maxSupply;
    maxMintAmountPerWallet = _maxMintAmountPerWallet;
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerWallet, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _;
  }

  function devMint(uint256 _mintAmount) external onlyOwner {
    require(paused, "The contract should be paused!");
    require(totalSupply() + _mintAmount <= maxAmountForTeamsReserve, "Too many already minted before dev mint");

    uint256 totalMints = _mintAmount / maxMintAmountPerWallet;
    for (uint256 i = 0; i < totalMints; i++) {
      _safeMint(msg.sender, maxMintAmountPerWallet);
    }
  }

  function staffMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(staffMintEnabled, "The staff mint is not enabled!");
    require(staffMintClaimed[msg.sender]  + _mintAmount <= maxMintAmountPerWallet, "Mint for staff already claimed!");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");

    staffMintClaimed[msg.sender] = staffMintClaimed[msg.sender] + 1;
    _safeMint(msg.sender, _mintAmount);
  }

  function vipMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify vip requirements
    require(vipMintEnabled, "The vip sale is not enabled!");
    require(vipMintClaimed[msg.sender] + _mintAmount <= maxMintAmountPerWallet, "Max mint for vip already reached!");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");

    vipMintClaimed[msg.sender] = vipMintClaimed[msg.sender] + 1;
    _safeMint(msg.sender, _mintAmount);
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, "The whitelist sale is not enabled!");
    require(whitelistMintClaimed[msg.sender] + _mintAmount <= maxMintAmountPerWallet, "Max mint for whitelist already reached!");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");

    whitelistMintClaimed[msg.sender] = whitelistMintClaimed[msg.sender] + 1;
    _safeMint(msg.sender, _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    require(staffMintClaimed[msg.sender] + _mintAmount <= maxMintAmountPerWallet, "Max mint per wallet address already reached!");
    require(vipMintClaimed[msg.sender] + _mintAmount <= maxMintAmountPerWallet, "Max mint per wallet address already reached!");
    require(whitelistMintClaimed[msg.sender] + _mintAmount <= maxMintAmountPerWallet, "Max mint per wallet address already reached!");
    require(publicMintClaimed[msg.sender] + _mintAmount <= maxMintAmountPerWallet, "Max mint per wallet address already reached!");

    publicMintClaimed[msg.sender] = publicMintClaimed[msg.sender] + 1;
    _safeMint(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
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

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerWallet(uint256 _maxMintAmountPerWallet) public onlyOwner {
    maxMintAmountPerWallet = _maxMintAmountPerWallet;
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

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setStaffMintEnabled(bool _state) public onlyOwner {
    staffMintEnabled = _state;
  }

  function setVIPMintEnabled(bool _state) public onlyOwner {
    vipMintEnabled = _state;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    if(revealed == false) {
      return hiddenMetadataUri;
    }

    return uriPrefix;
  }

  function _baseExtension() internal view virtual override returns (string memory) {
    return uriSuffix;
  }

  function _revealed() internal view virtual override returns (bool _state) {
    return revealed;
  }
}