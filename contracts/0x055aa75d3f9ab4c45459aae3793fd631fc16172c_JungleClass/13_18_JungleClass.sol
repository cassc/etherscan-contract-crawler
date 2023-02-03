// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;
import "hardhat/console.sol";

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract JungleClass is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  bytes32 public merkleRoot2;
  mapping(address => bool) public whitelistClaimed;
  mapping(address => bool) public whitelistClaimed2;
  mapping(address => bool) public whitelistClaimed3;
  mapping(address => bool) public whitelistClaimed4;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public cost2;
  uint256 public cost3;
  uint256 public cost4;
  uint256 public cost5;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }
  modifier mintPriceCompliance2() {
    require(msg.value >= cost2, 'Insufficient funds!');
    _;
  }
  modifier mintPriceCompliance3() {
    require(msg.value >= cost3, 'Insufficient funds!');
    _;
  }
  modifier mintPriceCompliance4() {
    require(msg.value >= cost4, 'Insufficient funds!');
    _;
  }
  modifier mintPriceCompliance5() {
    require(msg.value >= cost5, 'Insufficient funds!');
    _;
  }

  function whitelistMint(bytes32[] calldata _merkleProof, bytes32[] calldata _merkleProof2) public payable mintCompliance(1) mintPriceCompliance(1) {
    // Verify whitelist requirements

    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));


    if (MerkleProof.verify(_merkleProof2, merkleRoot2, leaf) && (!whitelistClaimed[_msgSender()] || !whitelistClaimed2[_msgSender()])){
      if (!whitelistClaimed[_msgSender()]){
        whitelistClaimed[_msgSender()] = true;
        return _safeMint(_msgSender(), 1);
      }else if (!whitelistClaimed2[_msgSender()]){
        whitelistClaimed2[_msgSender()] = true;
        return _safeMint(_msgSender(), 1);
      }
    }else if (MerkleProof.verify(_merkleProof, merkleRoot, leaf) && (!whitelistClaimed3[_msgSender()] || !whitelistClaimed4[_msgSender()])){
      if (!whitelistClaimed3[_msgSender()]){
        whitelistClaimed3[_msgSender()] = true;
        return _safeMint(_msgSender(), 1);
      }else if (!whitelistClaimed4[_msgSender()]){
        whitelistClaimed4[_msgSender()] = true;
        return _safeMint(_msgSender(), 1);
      }
    }else{
      require(false, 'Invalid proof!');
    }

    require(false, 'Not in any condition!');
  }

  function whitelistMint2(bytes32[] calldata _merkleProof, bytes32[] calldata _merkleProof2) public payable mintCompliance(2) mintPriceCompliance(2) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

    if (MerkleProof.verify(_merkleProof2, merkleRoot2, leaf) && (!whitelistClaimed[_msgSender()] || !whitelistClaimed2[_msgSender()])){
      if (!whitelistClaimed[_msgSender()] && !whitelistClaimed2[_msgSender()]){
        whitelistClaimed[_msgSender()] = true;
        whitelistClaimed2[_msgSender()] = true;
        return _safeMint(_msgSender(), 2);
      }
    }else if (MerkleProof.verify(_merkleProof, merkleRoot, leaf) && (!whitelistClaimed3[_msgSender()] || !whitelistClaimed4[_msgSender()])){
      if (!whitelistClaimed3[_msgSender()] && !whitelistClaimed4[_msgSender()]){
        whitelistClaimed3[_msgSender()] = true;
        whitelistClaimed4[_msgSender()] = true;
        return _safeMint(_msgSender(), 2);
      }
    }else{
      require(false, 'Invalid proof!');
    }

    require(false, 'Not in any condition!');
  }

  function mint() public payable mintCompliance(1) mintPriceCompliance(1) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), 1);
  }
  function mint2() public payable mintCompliance(2) mintPriceCompliance2() {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), 2);
  }

  function mint3() public payable mintCompliance(3) mintPriceCompliance3() {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), 3);
  }
  function mint4() public payable mintCompliance(4) mintPriceCompliance4() {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), 4);
  }
  function mint5() public payable mintCompliance(5) mintPriceCompliance5() {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), 5);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

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

  function setCost2(uint256 _cost) public onlyOwner {
    cost2 = _cost;
  }

  function setCost3(uint256 _cost) public onlyOwner {
    cost3 = _cost;
  }

  function setCost4(uint256 _cost) public onlyOwner {
    cost4 = _cost;
  }

  function setCost5(uint256 _cost) public onlyOwner {
    cost5 = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
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

  function setMerkleRoot2(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot2 = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}