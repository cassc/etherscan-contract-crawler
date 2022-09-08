// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';


contract FelizPass is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  string public uriPrefix = 'ipfs://QmPZuFQnNPaxnibsv6ZKq6cNabiaPiUSTK6hAbxWRirs6p/';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost = 0 ether;
  uint256 public supportDonateMin = 0.005 ether;
  uint256 public maxSupply = 500;
  uint256 public maxMintAmountPerTx = 1;
  uint256 public maxNFTPerAccount = 1;
  uint256 public maxNFTforSupporter = 186; // This is for supporter who donate fund to drive project, it's FCFS.
  mapping(address => uint256) public addressMintedBalance;
  uint256 public whitelistEndDate = 1662998400;

  bool public paused = true;
  bool public revealed = true;
  bool public isWhitelistRound = true;
  bytes32 public whitelistSAP;

  constructor(
  ) ERC721A("Feliz Pass", "FELIZPASS") {
    setHiddenMetadataUri("ipfs://QmPZuFQnNPaxnibsv6ZKq6cNabiaPiUSTK6hAbxWRirs6p/1.json");
    _safeMint(_msgSender(), 30);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "max NFT limit exceeded!");
    require(_mintAmount + addressMintedBalance[msg.sender] <= maxNFTPerAccount, "You reach maximum NFT per address!");
    _;
  }

  modifier notSmartContract() {
    require(msg.sender == tx.origin, "You cannot mint from smart contract");
    _;
  }

  function mintPass(uint256 _mintAmount, bytes32[] calldata merkleProof) public payable nonReentrant notSmartContract mintCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    if(block.timestamp < whitelistEndDate) {
      require(isValidMerkleProof(merkleProof, whitelistSAP), "This is SAP holder round!");
      require(msg.value >= _getCurrentPrice(_mintAmount, merkleProof), "Insufficient funds!");
      addressMintedBalance[_msgSender()] = addressMintedBalance[_msgSender()] + _mintAmount;

      if (msg.value >= supportDonateMin && maxNFTforSupporter > 0 && (maxSupply - totalSupply() > 1)){
        maxNFTforSupporter = maxNFTforSupporter - 1;
        _mintAmount = _mintAmount + 1;
      }

      _safeMint(_msgSender(), _mintAmount);
    }else{
      require(!isWhitelistRound, "This is whitelist round but the time is ended!");
      require(msg.value >= _getCurrentPrice(_mintAmount, merkleProof), "Insufficient funds!");

      addressMintedBalance[_msgSender()] = addressMintedBalance[_msgSender()] + _mintAmount;
      _safeMint(_msgSender(), _mintAmount);
    }
  }

  function giftForAddress(address[] calldata receivers, uint256 _amount) external onlyOwner {
    require(totalSupply() + _amount <= maxSupply, "max NFT limit exceeded!");
    for (uint256 i = 0; i < receivers.length; i++) {
      _safeMint(receivers[i], _amount);
    }
  }

  function _getCurrentPrice(uint256 _mintAmount, bytes32[] calldata merkleProof) internal view returns (uint256) {
    uint256 finalPrice;
      if(isValidMerkleProof(merkleProof,whitelistSAP) && block.timestamp < whitelistEndDate){
          finalPrice = _mintAmount * cost;
          return finalPrice;
        } else {
          finalPrice = _mintAmount * supportDonateMin;
          return finalPrice;
        }
  }

  function isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) private view returns (bool) {
        if(MerkleProof.verify(merkleProof,root,keccak256(abi.encodePacked(msg.sender)))){
          return true;
        }else{
          return false;
        }           
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
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setSAPEndDate(uint256 _date) public onlyOwner {
    whitelistEndDate = _date;
  }

  function setMaxPerWallet(uint256 _amount) public onlyOwner {
    maxNFTPerAccount = _amount;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setCostDonate(uint256 _cost) public onlyOwner {
    supportDonateMin = _cost;
  }

  function setMaxNFTForSupporter(uint256 _amount) public onlyOwner {
    maxNFTforSupporter = _amount;
  }

  function setWhitelistRound(bool _wl) public onlyOwner {
    isWhitelistRound = _wl;
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

  function setwhitelistSAP(bytes32 merkleRoot) external onlyOwner {
    whitelistSAP = merkleRoot;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}