// SPDX-License-Identifier: MIT

//     (()__(()
//      /       \ 
//     ( /    \  \
//      \ o o    /
//      (_()_)__/ \             
//     / _,==.____ \
//    (   |--|      )
//    /\_.|__|'-.__/\_
//   / (        /     \ 
//   \  \      (      /
//    )  '._____)    /    
// (((____.--(((____/
//  ME AND MY FRIEND

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract MAMF is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;
  using SafeMath for uint256; 

  bytes32 public merkleRoot;

  mapping(address => bool) public whitelistClaimed;
  mapping(address => uint) public mintedByOwner;
  
  string private baseMetadataUri;
  
  uint256 public cost = 0.0066 ether;
  uint256 public maxSupply = 5000;
  uint256 public maxMintAmountPerTx = 5;
  uint256 public maxWhitelistMintAmountPerTx = 1;
  uint256 public maxPerWallet = 100;
  
  bool public paused = true;
  bool public whitelistMintEnabled = false;

  string public uriSuffix = '.json';
  
  struct Friend {
    uint trainingPoints;
    uint strength;
    uint stamina;
    uint agility;
    uint iq;
  }
  mapping(uint => Friend) public friends;

  struct Training {
      uint startTime;
  }
  mapping(uint => Training) public friendsTraining;
  
  constructor() ERC721A("ME AND MY FRIEND", "MAMF") {}

  function startTrainingFriend(uint256 _tokenId) public friendOwnerCompliance(_tokenId) {
    friendsTraining[_tokenId].startTime = block.timestamp;
  }
  
  function stopAndClaimTrainingFriend(uint256 _tokenId) public friendOwnerCompliance(_tokenId) {
    addTrainingPointsToFriend(_tokenId);
    friendsTraining[_tokenId].startTime = 0;
  }

  function claimTrainingPoints(uint256 _tokenId) public friendOwnerCompliance(_tokenId) {
    addTrainingPointsToFriend(_tokenId);
    startTrainingFriend(_tokenId);
  }

  function addTrainingPointsToFriend(uint256 _tokenId) internal {
    friends[_tokenId].trainingPoints += calculateTrainingPointsToClaim(_tokenId); 
  }

  function spendTrainingPoints(uint256 _tokenId, uint256 _strength, uint256 _stamina, uint256 _agility, uint256 _iq) public friendOwnerCompliance(_tokenId) {
    uint256 totalPointsToSpend = _strength + _stamina + _agility + _iq;
    require(friends[_tokenId].trainingPoints >= totalPointsToSpend, "You do not have enough training points.");

    require(friends[_tokenId].strength + _strength <= 100, "You can not exceed 100 strength.");
    require(friends[_tokenId].stamina + _stamina <= 100, "You can not exceed 100 stamina.");
    require(friends[_tokenId].agility + _agility <= 100, "You can not exceed 100 agility.");
    require(friends[_tokenId].iq + _iq <= 100, "You can not exceed 100 iq.");

    friends[_tokenId].strength += _strength;
    friends[_tokenId].stamina += _stamina;
    friends[_tokenId].agility += _agility;
    friends[_tokenId].iq += _iq;

    friends[_tokenId].trainingPoints -= totalPointsToSpend;
  }
  
  modifier friendOwnerCompliance(uint256 _tokenId) {
    require(ownerOf(_tokenId) == _msgSender(), "You do not own this friend.");
    _;
  }

  function calculateTrainingPointsToClaim(uint256 _tokenId) public view returns (uint256 points) {
    if (friendsTraining[_tokenId].startTime == 0){
      return 0;
    }

    return block.timestamp.sub(friendsTraining[_tokenId].startTime).div(60).div(60);
  }
  
  function getFriendByTokenId(uint256 _tokenId) public view returns (Friend memory) {
    return friends[_tokenId];
   }
   
   function getTrainingByTokenId(uint256 _tokenId) public view returns (Training memory) {
    return friendsTraining[_tokenId];
   }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount + mintedByOwner[_msgSender()] <= maxPerWallet);
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintWhitelistCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxWhitelistMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public mintWhitelistCompliance(_mintAmount) {
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    internalMint(_mintAmount, true);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    internalMint(_mintAmount, false);
  }
  
  function internalMint(uint256 _amount, bool _whiteListed) internal {
    uint startIndex = _totalMinted() + 1;
    for (uint i = 0; i < _amount; i++)
    {
      uint freePoints = _totalMinted() + i <= 2500 ? 10 : 5;
      if (_whiteListed){
        freePoints = 10;
      }

      friends[startIndex + i] = Friend(freePoints,0,0,0,0);
      friendsTraining[startIndex + i] = Training(0);
    }
      
    mintedByOwner[_msgSender()] += _amount;
    _safeMint(_msgSender(), _amount);
  }

  function teamMint(uint256 _teamAmount) external onlyOwner  {
    require(totalSupply() + _teamAmount <= maxSupply, 'Max supply exceeded!');
    internalMint(_teamAmount, true);
  }


  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }
  
  function _baseURI() internal view override returns (string memory) {
    return baseMetadataUri;
  }

  function changeFriend(uint256 _tokenId, uint256 _strength, uint256 _stamina, uint256 _agility, uint256 _iq, uint _trainingPoints) public onlyOwner {
    friends[_tokenId].trainingPoints = _trainingPoints;
    friends[_tokenId].strength = _strength;
    friends[_tokenId].stamina = _stamina;
    friends[_tokenId].agility = _agility;
    friends[_tokenId].iq = _iq;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
    maxPerWallet = _maxPerWallet;
  }

  function setMxWhitelistMintAmountPerTx(uint256 _maxWhitelistMintAmountPerTx) public onlyOwner {
    maxWhitelistMintAmountPerTx = _maxWhitelistMintAmountPerTx;
  }

  function setBaseMetadataUri(string memory a) public onlyOwner {
    baseMetadataUri = a;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
  
  function transferFrom(address from, address to, uint256 tokenId) public payable virtual override(ERC721A, IERC721A) {
    super.transferFrom(from, to, tokenId);
    friendsTraining[tokenId] = Training(0);
  }

  
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }
}