// SPDX-License-Identifier: MIT



pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';


contract BirbsFriend is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost = 0 ether;
  uint256 public maxSupply = 2000;
  uint256 public sapLimit = 1900;
  mapping(address => uint256) public addressMintedBalance;     
  uint256 public whitelistEndDateVIP = 1659765600;
  uint256 public whitelistEndDate = 1659769200;
  uint256 public whitelistEndDateFriend = 1659772800;

  bool public paused = true;
  bool public revealed = false;
  bytes32 public whitelistInvestor;
  bytes32 public whitelistSupporter;
  bytes32 public whitelistHolder;
  bytes32 public whitelistFriend;


  constructor(
  ) ERC721A("Birds Friend", "BIRBS") {
    setHiddenMetadataUri("ipfs://QmayRtaWHRRfBCSJx7M4tGGreQanWan5mJziHHUvGFpRf3/hidden.json");
    _safeMint(_msgSender(), 50);
  }

  modifier notSmartContract() {
    require(msg.sender == tx.origin, "You cannot mint from smart contract");
    _;
  }

  function Mint(bytes32[] calldata merkleProof) public payable nonReentrant notSmartContract {
    require(!paused, 'The contract is paused!');
    uint256 mintAmount = getMintAmount(merkleProof); 

    if(block.timestamp < whitelistEndDateVIP) {
      if(!isValidMerkleProof(merkleProof, whitelistSupporter) && !isValidMerkleProof(merkleProof, whitelistInvestor)){
        revert("This is Investor and Supporter round! Please wait for the next round");
      }
      require(totalSupply() + mintAmount <= sapLimit, "You reach limit of this round!");
    }else if(block.timestamp > whitelistEndDateVIP && block.timestamp < whitelistEndDate){
      if(!isValidMerkleProof(merkleProof, whitelistSupporter) && 
         !isValidMerkleProof(merkleProof, whitelistInvestor) && 
        !isValidMerkleProof(merkleProof, whitelistHolder)){
        revert("This is SAP holder round! Please wait for the next round");
      }
      require(totalSupply() + mintAmount <= sapLimit, "You reach limit of this round!");
    }else if(block.timestamp > whitelistEndDate && block.timestamp < whitelistEndDateFriend){
      if(totalSupply() + mintAmount <= sapLimit){
        if(!isValidMerkleProof(merkleProof, whitelistSupporter) && 
           !isValidMerkleProof(merkleProof, whitelistInvestor) && 
           !isValidMerkleProof(merkleProof, whitelistHolder) &&
           !isValidMerkleProof(merkleProof, whitelistFriend)){
          revert("This is Birbs friend round! Please wait for public round");
        }
      }else{
        require(isValidMerkleProof(merkleProof, whitelistFriend), "This is Birbs friend round! Please wait for public round");
      }
    }
     
    require(totalSupply() + mintAmount <= maxSupply, 'max NFT limit exceeded!');
    require(addressMintedBalance[_msgSender()] <= 0, "You have already claimed Birbs Friend!");
    require(msg.value >= cost, 'Insufficient funds!');
    addressMintedBalance[_msgSender()] = addressMintedBalance[_msgSender()] + mintAmount;

    _safeMint(_msgSender(), mintAmount);
  }

  function giftForAddress(address[] calldata receivers, uint256 _amount) external onlyOwner {
    for (uint256 i = 0; i < receivers.length; i++) {
      _safeMint(receivers[i], _amount);
    }
  }

  function BurnBirbs(uint256 _tokenID) external {
    _burn(_tokenID, true);
  }

  function getMintAmount(bytes32[] calldata merkleProof) public view returns (uint256) {
    if(isValidMerkleProof(merkleProof, whitelistInvestor)){
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

  function setPresaleEndDateFriend(uint256 _date) external onlyOwner {
    whitelistEndDateFriend = _date;
  }

  function setPresaleEndDate(uint256 _date) external onlyOwner {
    whitelistEndDate = _date;
  }

  function setPresaleEndDateVIP(uint256 _date) external onlyOwner {
    whitelistEndDateVIP = _date;
  }

  function setRevealed(bool _state) external onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) external onlyOwner {
    cost = _cost;
  }

  function setSAPLimit(uint256 _limit) external onlyOwner {
    require(_limit < maxSupply, "You set wrong limit");
    sapLimit = _limit;
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

  function setwhitelistFriend(bytes32 merkleRoot) external onlyOwner {
        whitelistFriend = merkleRoot;
  }

  function setwhitelistHolder(bytes32 merkleRoot) external onlyOwner {
        whitelistHolder = merkleRoot;
  }

  function setwhitelistSupporter(bytes32 merkleRoot) external onlyOwner {
        whitelistSupporter = merkleRoot;
  }

  function setwhitelistInvestor(bytes32 merkleRoot) external onlyOwner {
        whitelistInvestor = merkleRoot;
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