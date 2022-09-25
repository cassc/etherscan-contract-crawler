// SPDX-License-Identifier: MIT



pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';


contract FxckHero is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost = 0 ether;
  uint256 public maxSupply = 3456;
  mapping(address => uint256) public addressMintedBalance;     
  uint256 public whitelistEndDate = 1664128800;
 

  bool public paused = true;
  bool public revealed = false;
  bytes32 public whitelistGet2;
  bytes32 public whitelist;


  constructor(
  ) ERC721A("Fxck Face Hero", "FXCKHERO") {
    setHiddenMetadataUri("ipfs://QmNmEpAe1a6kexK9PhhuDVhirJbiWGtXf8J7B9fLb7HXUF/hidden.json");
    // _safeMint(_msgSender(), 50);
  }

  modifier notSmartContract() {
    require(msg.sender == tx.origin, "You cannot mint from smart contract");
    _;
  }

  function Mint(bytes32[] calldata merkleProof) public payable nonReentrant notSmartContract {
    require(!paused, 'The contract is paused!');
    uint256 mintAmount = getMintAmount(merkleProof); 

    if(block.timestamp < whitelistEndDate) {
      if(!isValidMerkleProof(merkleProof, whitelist) && !isValidMerkleProof(merkleProof, whitelistGet2)){
        revert("This is Whitelist round! Please wait for public round");
      }
    }
    require(totalSupply() + mintAmount <= maxSupply, 'max NFT limit exceeded!');
    require(addressMintedBalance[_msgSender()] <= 0, "You have already claimed Fxck Hero!");
    require(msg.value >= cost, 'Insufficient funds!');
    addressMintedBalance[_msgSender()] = addressMintedBalance[_msgSender()] + mintAmount;

    _safeMint(_msgSender(), mintAmount);
  }

  function giftForAddress(address[] calldata receivers, uint256 _amount) external onlyOwner {
    for (uint256 i = 0; i < receivers.length; i++) {
      _safeMint(receivers[i], _amount);
    }
  }

  function BurnHero(uint256 _tokenID) external {
    _burn(_tokenID, true);
  }

  function getMintAmount(bytes32[] calldata merkleProof) public view returns (uint256) {
    if(isValidMerkleProof(merkleProof, whitelistGet2)){
      if(totalSupply() + 2 > maxSupply){
        return 1;
      }else{
        return 2;
      }
    }else {
      return 1;
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
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setWhitelistEndDate(uint256 _date) external onlyOwner {
    whitelistEndDate = _date;
  }

  function setRevealed(bool _state) external onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) external onlyOwner {
    cost = _cost;
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

  function setPaused(bool _state) external onlyOwner {
    paused = _state;
  }

  function setwhitelist(bytes32 merkleRoot) external onlyOwner {
        whitelist = merkleRoot;
  }

  function setwhitelistGet2(bytes32 merkleRoot) external onlyOwner {
        whitelistGet2 = merkleRoot;
  }

  function burnAll() external onlyOwner {
        maxSupply = totalSupply();
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}