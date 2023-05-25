// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
 
//        __  _______  ____  _  ______________  __   ____
//       /  |/  / __ \/ __ \/ |/ / ___/  _/ _ \/ /  / __/
//      / /|_/ / /_/ / /_/ /    / (_ // // , _/ /___\ \  
//     /_/  /_/\____/\____/_/|_/\___/___/_/|_/____/___/  
//                                                       

contract MoongirlsEmanueleFerrari is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32[] public merkleRoots;

  mapping(address => bool) public alreadyMinted;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  uint256 public cost;
  uint256 public maxSupply;

  bool public paused = true;
  bool public whitelistMintEnabled = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    string memory _metadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setUriPrefix(_metadataUri);
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!alreadyMinted[_msgSender()], 'Address already minted!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    uint256 maxMintNumber = getMaxMintNumber(_merkleProof);
    require(maxMintNumber > 0, 'Invalid proof!');
    require(_mintAmount > 0 && _mintAmount <= maxMintNumber, 'Invalid mint amount!');
    alreadyMinted[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mintPublic(uint256 _mintAmount) public payable mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    require(!whitelistMintEnabled, 'The whitelist sale is enabled!');
    require(_mintAmount > 0 && _mintAmount <= 1, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    require(!alreadyMinted[_msgSender()], 'Address already minted!');
    alreadyMinted[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
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

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
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

  function setMerkleRoots(bytes32[] calldata _merkleRoots) public onlyOwner {
    merkleRoots = _merkleRoots;
  }

  function getMaxMintNumber(bytes32[] calldata _merkleProof) public view returns (uint256) {
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

    for (uint256 i = 0; i < 10; i++) {
       if(MerkleProof.verify(_merkleProof, merkleRoots[i], leaf)){
        return i + 1;
       }
    }

    return 0;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}

// developed by Kanye East