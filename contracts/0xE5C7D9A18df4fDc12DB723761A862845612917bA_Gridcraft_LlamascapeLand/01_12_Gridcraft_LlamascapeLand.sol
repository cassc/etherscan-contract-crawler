// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721P.sol";

contract Gridcraft_LlamascapeLand is ERC721P, Ownable {

  string private baseTokenURI = " ipfs://QmPRcB57ojGAXsMvZSuQ4UTWkfaTWGNm8fdJAaUpDEc8ne/";
  string public provenance = "";
  uint256 public startingIndexBlock;
  uint256 public startingIndex;

  uint256 public revealDate = 4796668800;

  uint256 public maxSupply = 9800;
  uint256 public reserved = 650;

  address public mintCoordinator;

  modifier onlyCoordinator {
    require (_msgSender() == mintCoordinator, "Not allowed");
    _;
  }

  constructor() ERC721P("Llamascape Land", "LLAMALAND") {}

  function saleMint(address _recepient, uint256 _amount, bool _startStaking) external onlyCoordinator {
    mint(_amount, _recepient, _startStaking);
  }

  function ownerMint(address _recepient, uint256 _amount, bool _startStaking) external onlyOwner {
    require(totalSupply() + _amount <= maxSupply, "Exceeds max supply");
    require(_amount <= reserved, "Amount exceeds reserve");
    unchecked {
        reserved -= _amount;
    }
    
    mint(_amount, _recepient, _startStaking);
  }

  function mint(uint256 _amount, address _recepient, bool _startStaking) internal {
    for (uint i; i<_amount; ){
      _safeMint(_recepient);
      if (_startStaking){
        _stake(uint16(totalSupply()));
      }
      unchecked { ++i; }
    }

    if (startingIndexBlock == 0 && (totalSupply() == maxSupply || block.timestamp > revealDate)) {
        _setStartingIndex();
    } 
  }

   function stake(uint16[] memory _tokenIds) external {
    for (uint i; i < _tokenIds.length ;){
      require(ownerOf(_tokenIds[i]) == msg.sender, "Not owned or already staked");
      _stake(_tokenIds[i]);
      unchecked { ++i; }
    }
  }

  function stakeAll() external {
    uint16[] memory tokensOwned = tokensOfOwner(msg.sender);
    for (uint i; i < tokensOwned.length ; ){
      if (ownerOf(tokensOwned[i]) == msg.sender) {
        _stake(tokensOwned[i]);
      }
      unchecked { ++i; }
    }
  }

  function unstake(uint16[] memory _tokenIds) external {
    require(isTrueOwnerOfTokens(msg.sender, _tokenIds), "Not owned");
    for (uint i; i < _tokenIds.length ;){
      require(isTokenStaked(_tokenIds[i]), "Not staked");
      _unstake(msg.sender, _tokenIds[i]);
      unchecked { ++i; }
    }
  }

  function unstakeAll() external {
    uint16[] memory tokensOwned = tokensOfOwner(msg.sender);
    for (uint i; i < tokensOwned.length ; ){
      if (ownerOf(tokensOwned[i]) != msg.sender) {
        _unstake(msg.sender, tokensOwned[i]);
      }
      unchecked { ++i; }
    }
  }

  // internal

  function _stake(uint16 _tokenId) internal {
    _owners[_tokenId] = address(this);
    emit Transfer(ownerOf(_tokenId), address(this), _tokenId);
  }

  function _unstake(address _realOwner, uint16 _tokenId) internal {
    _owners[_tokenId] = _realOwner;
    emit Transfer(address(this), _realOwner, _tokenId);
  }

  function _setStartingIndex() internal {
    require(startingIndexBlock == 0, "Starting index already set");

    startingIndexBlock = block.number - 1;

    startingIndex = uint(blockhash(startingIndexBlock)) % maxSupply;
  }

  // getters
    
  function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
  }

  function baseURI() public view returns (string memory) {
    return _baseURI();
  }

  function isTokenStaked(uint16 _tokenId) public view returns (bool) {
    return ownerOf(_tokenId) == address(this);
  }

  // returns number of tokens staked by user
  function stakedNumberByOwner(address _user) public view returns (uint16 stakedCount) {
    uint16[] memory tokensOwned = tokensOfOwner(_user);
    for (uint i; i < tokensOwned.length ;) {
      if (isTokenStaked(tokensOwned[i])){
        ++stakedCount;
      }
      unchecked { ++i; }
    }
  }

  function unstakedNumberByOwner(address _user) public view returns (uint16 unstakedCount) {
    uint16[] memory tokensOwned = tokensOfOwner(_user);
    for (uint i; i < tokensOwned.length ;) {
      if (!isTokenStaked(tokensOwned[i])){
        ++unstakedCount;
      }
      unchecked { ++i; }
    }
  }

  // returns array of tokenIds staked by user
  function stakedIdsByOwner(address _user) external view returns (uint16[] memory) {
    uint16[] memory tokensOwned = tokensOfOwner(_user);
    uint stakedCount = stakedNumberByOwner(_user);
    uint16[] memory tokensStaked = new uint16[](stakedCount);
    uint idx;
    for (uint i; i < tokensOwned.length ;) {
      if (isTokenStaked(tokensOwned[i])){
        tokensStaked[idx] = tokensOwned[i];
        ++idx;
      }
      unchecked { ++i; }
    }
    return tokensStaked;
  }

  function unstakedIdsByOwner(address _user) external view returns (uint16[] memory) {
    uint16[] memory tokensOwned = tokensOfOwner(_user);
    uint unstakedCount = unstakedNumberByOwner(_user);
    uint16[] memory tokensUnstaked = new uint16[](unstakedCount);
    uint idx;
    for (uint i; i < tokensOwned.length ;) {
      if (!isTokenStaked(tokensOwned[i])){
        tokensUnstaked[idx] = tokensOwned[i];
        ++idx;
      }
      unchecked { ++i; }
    }
    return tokensUnstaked;
  }

  function isTrueOwnerOfTokens(address _user, uint16[] memory _tokenIds) public view returns (bool) {
    bool found;
    uint16[] memory tokensOwned = tokensOfOwner(_user);
    for (uint i; i < _tokenIds.length ; ) {
      found = false;
      for (uint j; j < tokensOwned.length ; ) {  
        if (_tokenIds[i] == tokensOwned[j]){
          found = true;
          break;
        }
        unchecked { ++j; }
      }
      if (!found) return false;
      unchecked { ++i; }
    }
    return true;
  }

  function remaining() public view returns (uint256 nftsRemaining){
    unchecked{
      nftsRemaining = maxSupply - totalSupply() - reserved;
    }
  }

  // Owner setters

  function setCoordinator(address _newCoordinator) external onlyOwner {
    mintCoordinator = _newCoordinator;
  }

  function setBaseURI(string calldata _newBaseTokenURI) external onlyOwner {
    baseTokenURI = _newBaseTokenURI;
  }

  function setRevealDate(uint256 _newReveal) external onlyOwner {
    revealDate = _newReveal;
  }

  function setProvenanceHash(string memory provenanceHash) external onlyOwner {
    provenance = provenanceHash;
  }

}