// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

// Copyright 2022 Juxhino Radhima
// Author: Juxhino Radhima <[email protected]> @juxhinr

contract Kitsune is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  mapping(address => bool) private operators;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost; // (wei)
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;
            
  bool public mutableTokenUtilityStatus = false;
  uint public maxMutableTokenExpiryTime = 365; // days
  uint256 public mutableTokenFee; // (wei)
  uint256 public hardResetMutableTokenFee; // (wei)

  struct mutableToken {
    string URI;
    uint expiryDate;
    bool isActive;
  }

  struct hardResetMutableToken {
    bytes32 temporaryHash;
    bool isRequested;
  }

  mapping(uint256 => mutableToken) private mutableTokens;
  mapping(uint256 => hardResetMutableToken) private tempHardResetTokenHashes;

  mapping(uint256 => bool) public blacklistedMutableTokensURI;

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
    if(!isOwner()) {
      require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    }
    
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  modifier onlyTokenOwner(uint256 _tokenId) {
    require(ownerOf(_tokenId) == _msgSender(), "Must be called by token owner");
    _;
  }

  modifier onlyContractOperator() {
    require(isOwner() || hasOperatorRole(_msgSender()), "Caller is not the contract owner or operator");
    _;
  }

  function isOwner() internal view returns (bool) {
    if(owner() == _msgSender()) {
      return true;
    }

    return false;
  }

  function hasOperatorRole(address account) public view returns (bool) {
    if(operators[account] == true) {
      return true;
    }

    return false;
  }

  function grantOperatorRole(address account) external onlyOwner {
    if (!hasOperatorRole(account)) {
        operators[account] = true;
    }
  }

  function revokeOperatorRole(address account) external onlyOwner {
    if (hasOperatorRole(account)) {
        operators[account] = false;
    }
  }

  function setMutableTokenUtilityStatus(bool _newStatus) external onlyOwner {
    mutableTokenUtilityStatus = _newStatus;
  }

  function setMutableTokenFee(uint256 _newMutableTokenFee) external onlyOwner {
    mutableTokenFee = _newMutableTokenFee;
  }

  function setMutableTokenMaxExpiryTime(uint _newMaxExpiryTime) external onlyOwner {
    maxMutableTokenExpiryTime = _newMaxExpiryTime;
  }

  function setMutableTokenURI(uint256 _tokenId, string memory _tokenURI, uint _newExpiryDate) external payable onlyTokenOwner(_tokenId) {
    require(_exists(_tokenId), "Token does not exist");
    require(mutableTokenUtilityStatus == true, "Mutable Token Utility is disabled");
    require(msg.value >= mutableTokenFee, "Invalid mutate token fee amount");
    require(bytes(_tokenURI).length > 0, "Token URI cannot be empty");

    // Check if actual mutable token URI is blocked
    if(mutableTokens[_tokenId].expiryDate > 0) {
      require(block.timestamp > mutableTokens[_tokenId].expiryDate, "Mutable Token URI is blocked untill expiry date and cannot be changed");
    }

    // If expiryDate is 0, the mutable token is not blocked and does not expire

    // Check if the new mutable token expiry date is set properly
    if(_newExpiryDate > 0) {
      require(_newExpiryDate >= block.timestamp, "The expiry date cannot be in the past");
      uint256 limitExpiryDate = block.timestamp + (maxMutableTokenExpiryTime * 24*60*60);
      require(_newExpiryDate <= limitExpiryDate, "The expiry date cannot exceed the maximum expiration time");
    }

    mutableTokens[_tokenId].URI = _tokenURI;
    mutableTokens[_tokenId].expiryDate = _newExpiryDate;
    mutableTokens[_tokenId].isActive = true;
  }

  function disableMutableTokenURI(uint256 _tokenId) external onlyTokenOwner(_tokenId) {
    require(_exists(_tokenId), "Token does not exist");
    require(mutableTokenUtilityStatus == true, "Mutable Token Utility is disabled");

    if(mutableTokens[_tokenId].expiryDate > 0) {
      require(block.timestamp > mutableTokens[_tokenId].expiryDate, "Mutable Token URI is blocked untill expiry date and cannot be changed");
    }

    mutableTokens[_tokenId].URI = '';
    mutableTokens[_tokenId].expiryDate = 0;
    mutableTokens[_tokenId].isActive = false;
  }

  function operatorDisableMutableTokenURI(uint256 _tokenId) external onlyContractOperator {
    require(_exists(_tokenId), "Token does not exist");

    mutableTokens[_tokenId].URI = '';
    mutableTokens[_tokenId].expiryDate = 0;
    mutableTokens[_tokenId].isActive = false;
  }

  function requestHardResetMutableTokenURI(uint256 _tokenId) external payable onlyTokenOwner(_tokenId) {
    require(_exists(_tokenId), "Token does not exist");
    require(mutableTokenUtilityStatus == true, "Mutable Token Utility is disabled");
    require(msg.value >= hardResetMutableTokenFee, "Invalid hard reset token fee amount");

    tempHardResetTokenHashes[_tokenId].isRequested = true;
  }

  function getTemporaryMutableTokenHashRequestStatus(uint256 _tokenId) external view returns (bool) {
    require(_exists(_tokenId), "Token does not exist");

    return tempHardResetTokenHashes[_tokenId].isRequested;
  }

  function setHardResetMutableTokenFee(uint256 _newResetMutableTokenFee) external onlyOwner {
    hardResetMutableTokenFee = _newResetMutableTokenFee;
  }

  function setTemporaryMutableTokenHash(uint256 _tokenId, bytes32 _temporaryHash) external onlyContractOperator {
    require(_exists(_tokenId), "Token does not exist");

    tempHardResetTokenHashes[_tokenId].temporaryHash = _temporaryHash;
  }

  function getTemporaryMutableTokenHash(uint256 _tokenId) external view returns (bytes32) {
    require(_exists(_tokenId), "Token does not exist");

    return tempHardResetTokenHashes[_tokenId].temporaryHash;
  }

  function hardResetMutableTokenURI(uint256 _tokenId, string memory _temporaryPassword) external onlyTokenOwner(_tokenId) {
    require(_exists(_tokenId), "Token does not exist");
    require(mutableTokenUtilityStatus == true, "Mutable Token Utility is disabled");
    require(bytes(_temporaryPassword).length > 0, "Temporary Password cannot be empty");
    require(tempHardResetTokenHashes[_tokenId].isRequested, "Temporary hash has not been requested yet");

    bytes32 inputHash = keccak256(abi.encodePacked(_temporaryPassword));

    require(inputHash == tempHardResetTokenHashes[_tokenId].temporaryHash, "Invalid temporary password provided");

    mutableTokens[_tokenId].URI = '';
    mutableTokens[_tokenId].expiryDate = 0;
    mutableTokens[_tokenId].isActive = false;

    tempHardResetTokenHashes[_tokenId].temporaryHash = '';
    tempHardResetTokenHashes[_tokenId].isRequested = false;
  }

  function deleteTemporaryMutableTokenHash(uint256 _tokenId) external onlyContractOperator {
    require(_exists(_tokenId), "Token does not exist");

    tempHardResetTokenHashes[_tokenId].temporaryHash = '';
    tempHardResetTokenHashes[_tokenId].isRequested = false;
  }

  function blacklistMutableTokenURI(uint256 _tokenId, bool status) external onlyContractOperator {
    require(_exists(_tokenId), "Token does not exist");

    blacklistedMutableTokensURI[_tokenId] = status;
  }

  function mutableTokenURIBlacklistStatus(uint256 _tokenId) external view returns (bool) {
    require(_exists(_tokenId), "Token does not exist");

    return blacklistedMutableTokensURI[_tokenId];
  }

  function checkWhitelistClaimedStatus(address _address) external view returns (bool) {
    return whitelistClaimed[_address];
  }

  function setWhitelistClaimedStatus(address _address, bool _status) external onlyContractOperator {
    whitelistClaimed[_address] = _status;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    _safeMint(_msgSender(), _mintAmount);
    whitelistClaimed[_msgSender()] = true;
  }

  function mint(uint256 _mintAmount) external payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) external mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned) {
        if (ownership.addr != address(0)) {
          latestOwnerAddress = ownership.addr;
        }

        if (latestOwnerAddress == _owner) {
          ownedTokenIds[ownedTokenIndex] = currentTokenId;

          ownedTokenIndex++;
        }
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'Token does not exist');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    if(mutableTokenUtilityStatus == true && mutableTokens[_tokenId].isActive && bytes(mutableTokens[_tokenId].URI).length > 0 && blacklistedMutableTokensURI[_tokenId] == false) {
      return mutableTokens[_tokenId].URI;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function originalTokenURI(uint256 _tokenId) public view virtual returns (string memory) {
    require(_exists(_tokenId), 'Token does not exist');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) external onlyContractOperator {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyContractOperator {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyContractOperator {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMaxSupply(uint _newMaxSupply) external onlyOwner {
    require(maxSupply != _newMaxSupply, "New value matches old");
    require(_newMaxSupply >= totalSupply(), "The new supply is lower than the number of tokens minted");

    maxSupply = _newMaxSupply;
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

  function setPaused(bool _state) external onlyContractOperator {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyContractOperator {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) external onlyContractOperator {
    whitelistMintEnabled = _state;
  }

  function withdraw() external onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}