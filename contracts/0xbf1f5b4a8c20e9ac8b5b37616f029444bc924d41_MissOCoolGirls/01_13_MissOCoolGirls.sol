// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract MissOCoolGirls is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  uint256 public constant MAX_SUPPLY = 10000;


  uint256 public whitelistCost = .03 ether;
  uint256 public publicCost = .04 ether;
  uint public maxWhitelistMint = 5;
  uint public maxPublicMint = 200;
  uint256 public maxMintAmountPerTx = 20;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;
  bool public teamMinted = false;
  bool public publicSale = false;

  mapping(address => uint256) public totalPublicMint;
  mapping(address => uint256) public totalWhitelistMint;

  constructor() ERC721A("Miss O Cool Girls", "MOCG"){

  }

  modifier callerIsUser() {
      require(tx.origin == msg.sender, "Miss O Cool Girls :: Cannot be called by a contract");
      _;
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= MAX_SUPPLY, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= publicCost * _mintAmount, 'Insufficient funds!');
    _;
  }

  modifier whitelistPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= whitelistCost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) whitelistPriceCompliance(_mintAmount) callerIsUser {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require((totalWhitelistMint[msg.sender] + _mintAmount)  <= maxWhitelistMint, "Cannot mint beyond whitelist max mint!");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    totalWhitelistMint[msg.sender] += _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) callerIsUser {
    require(!paused, 'The contract is paused!');
    require((totalPublicMint[msg.sender] + _mintAmount)  <= maxPublicMint, "Cannot mint beyond whitelist max mint!");
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned && ownership.addr != address(0)) {
        latestOwnerAddress = ownership.addr;
      }

      if (latestOwnerAddress == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return bytes(hiddenMetadataUri).length > 0
        ? string(abi.encodePacked(hiddenMetadataUri, _tokenId.toString(), uriSuffix))
        : '';
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setPublicCost(uint256 _cost) public onlyOwner {
    publicCost = _cost;
  }

  function setWhitelistCost(uint256 _cost) public onlyOwner {
    whitelistCost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMaxPublicMint(uint256 _maxPublicMint) public onlyOwner {
    maxPublicMint = _maxPublicMint;
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

  function setWhitelistMint(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function togglePublicMint() public onlyOwner {
    publicSale = !publicSale;
  }

  function teamMint() external onlyOwner{
      require(!teamMinted, "Miss O Cool Girls :: Team already minted");
      teamMinted = true;
      _safeMint(msg.sender, 200);
  }

  function withdraw() public onlyOwner nonReentrant {
    uint256 balance = address(this).balance;
    payable(0x86f2db3EdD9Bf217057aD222c622153ACd5c92AF).transfer(balance * 33 / 100);
    payable(0x224758195A953F0bFd5450aaE77a1fC89F10Bc39).transfer(balance * 33 / 100);
    payable(0xb088E1D427FF9347366263149b1eCBb5a0A841e8).transfer(balance * 26 / 100);
    payable(0x82273e8dD7125A17E65D4D15B43b881957e07A48).transfer(balance * 8 / 100);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}