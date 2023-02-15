// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "operator-filter-registry/src/OperatorFilterer.sol";
   
//      ________    ______________________  __________   _       _____ _    ________
//     / ____/ /   / ____/ ____/_  __/ __ \/  _/ ____/  | |     / /   | |  / / ____/
//    / __/ / /   / __/ / /     / / / /_/ // // /       | | /| / / /| | | / / __/   
//   / /___/ /___/ /___/ /___  / / / _, _// // /___     | |/ |/ / ___ | |/ / /___   
//  /_____/_____/_____/\____/ /_/ /_/ |_/___/\____/     |__/|__/_/  |_|___/_____/                                

contract VisionOf2023 is ERC721A, Ownable, ReentrancyGuard, OperatorFilterer {

  using StringsUpgradeable for uint256;

  bytes32 public merkleRoot;

  mapping(address => bool) public claimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmount = 1;

  bool public paused = true;
  bool public whitelistMintEnabled = true;
  bool public closed = false;

  address VARI = 0x4cCCD532d6E06f1A1fCd16A120757e7677DC7aF2;
  address AbtomAL =	0xB77D31D715D9aA1536fDcc32A1BBc6Ff25A06309;
  address Drvmmer =	0xf6015793A8444f1BFfc67780fEbDb8941D1Ec75E;
  address FreshStuff= 0x951cB5AACe47865b96212f9B722bFd6f233EbFE4;
  address Zimoh =	0x08E209e86b685a0B748Be2985Ca9145e9cE912Bf;
  address NoiseParfumerie =	0x5E1375B73cF72dfcA20c69183A99fe107114BDa3;
  address Madflick = 0x904af0DAaF708b4292524e9BF0172d725044691b;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    string memory _metadataUri
  ) ERC721A(_tokenName, _tokenSymbol) OperatorFilterer(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), false) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setUriPrefix(_metadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(!closed, 'Contract closed');
    require(!paused, 'Contract paused');
    require(!claimed[_msgSender()], 'Address already minted!');
    require(_mintAmount > 0 && _mintAmount <= maxMintAmount, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    claimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintPriceCompliance(_mintAmount) {
    require(!whitelistMintEnabled, 'The public sale is not enabled!');
    require(!closed, 'Contract closed');
    require(!paused, 'Contract paused');
    require(_mintAmount > 0 && _mintAmount <= maxMintAmount, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(!closed, 'Contract closed');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
  }

  function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
      require(_maxMintAmount > 0, 'Invalid maxMintAmount');
      maxMintAmount = _maxMintAmount;
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

  function setVARI(address newAddress) public onlyOwner {
    VARI = newAddress;
  }

  function setAbtomAL(address newAddress) public onlyOwner {
    AbtomAL = newAddress;
  }

  function setDrvmmer(address newAddress) public onlyOwner {
    Drvmmer = newAddress;
  }

  function setFreshStuff(address newAddress) public onlyOwner {
    FreshStuff = newAddress;
  }

  function setZimoh(address newAddress) public onlyOwner {
    Zimoh = newAddress;
  }

  function setNoiseParfumerie(address newAddress) public onlyOwner {
    NoiseParfumerie = newAddress;
  }

  function setMadflick(address newAddress) public onlyOwner {
    Madflick = newAddress;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
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

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function closeEdition() public onlyOwner {
    closed = true;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function withdraw() public onlyOwner nonReentrant {
    // =============================================================================
    uint256 splitValue = address(this).balance * 715 / 10000;

    (bool payVARI, ) = payable(VARI).call{value: splitValue}('');
    require(payVARI);

    (bool payAbtomAL, ) = payable(AbtomAL).call{value: splitValue}('');
    require(payAbtomAL);

    (bool payDrvmmer, ) = payable(Drvmmer).call{value: splitValue}('');
    require(payDrvmmer);

    (bool payFreshStuff, ) = payable(FreshStuff).call{value: splitValue}('');
    require(payFreshStuff);

    (bool payZimoh, ) = payable(Zimoh).call{value: splitValue}('');
    require(payZimoh);

    (bool payNoiseParfumerie, ) = payable(NoiseParfumerie).call{value: splitValue}('');
    require(payNoiseParfumerie);

    (bool payMadflick, ) = payable(Madflick).call{value: splitValue}('');
    require(payMadflick);
    // =============================================================================

    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from){
        super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId)
      public
      payable
      override
      onlyAllowedOperator(from){
      super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
      public
      payable
      override
      onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId, data);
  }
}

// by 0x_wh04m1