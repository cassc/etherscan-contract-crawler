// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GMachine is ERC721, Ownable, ReentrancyGuard  {
  using Counters for Counters.Counter;
  using Strings for uint256;
  Counters.Counter _tokenIds;
  mapping(uint256 => string) _tokenURIs;
  mapping(string => uint) ipfsHashTokenIds;
  mapping(uint256 => bool) public lockedTokenIds;
  uint256 public cost = 0.001 ether;
  bool public paused = true;

  struct RenderToken {
    uint256 id;
    string uri;
  }

  constructor(string memory zeroURI) ERC721("GMachine", "GMACH") {
    uint256 newId = _tokenIds.current();
    _mint(_msgSender(), 0);
    _setTokenURI(newId, zeroURI);
    _tokenIds.increment();
    ipfsHashTokenIds[zeroURI] = newId;
    lockedTokenIds[newId] = false;
  }

    modifier tokenExists(uint _tokenId) {
    require(_exists(_tokenId), "This token does not exist.");
    _;
  }

  function setPaused() public onlyOwner {
    paused = !paused;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
    _tokenURIs[tokenId] = _tokenURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
  { require(_exists(tokenId)); 
    string memory _tokenURI = _tokenURIs[tokenId];
    return _tokenURI;
  }

  ///If using IPFS write "ipfs://CID" otherwise just a link to json file.
  function updateMetadataIPFSHash(uint _tokenId, string calldata _tokenMetadataIPFSHash) tokenExists(_tokenId) external {
    require(_msgSender() == ownerOf(_tokenId), "You are not the owner of this token.");
    require(!lockedTokenIds[_tokenId],"This token uri is locked");
    require(ipfsHashTokenIds[_tokenMetadataIPFSHash] == 0, "This IPFS hash has already been assigned.");
    _tokenURIs[_tokenId] = _tokenMetadataIPFSHash;
    ipfsHashTokenIds[_tokenMetadataIPFSHash] = _tokenId;
  }
  
  ///Once you lock the token it can't be reversed
  function lockTokenIDMetadata(uint _tokenId) tokenExists(_tokenId) external {
    require(_msgSender() == ownerOf(_tokenId), "You are not the owner of this token.");  
    require(!lockedTokenIds[_tokenId], "This token uri is already locked");
    lockedTokenIds[_tokenId] = true;
  }
  
  ///This function is for displaying on the fronend
  function getAllTokens() public view returns (RenderToken[] memory) {
    uint256 lastestId = _tokenIds.current();
    uint256 counter = 0;
    RenderToken[] memory res = new RenderToken[](lastestId);
    for (uint256 i = 0; i < lastestId; i++) {
      if (_exists(counter)) {
        string memory uri = tokenURI(counter);
        res[counter] = RenderToken(counter, uri);
      }
      counter++;
    }
    return res;
  }
  
  ///If minting from contract: if using IPFS write "ipfs://CID" otherwise just a link to json file.
  function mint(address recipient, string memory uri) public payable nonReentrant returns (uint256) {
    require(!paused, "The contract is paused!");
    require(msg.value == cost, "Insufficient funds!");
    require(ipfsHashTokenIds[uri] == 0, "This IPFS hash has already been assigned.");
    uint256 newId = _tokenIds.current();
    _mint(recipient, newId);
    _setTokenURI(newId, uri);
    _tokenIds.increment();
    ipfsHashTokenIds[uri] = newId;
    lockedTokenIds[newId] = false;
    return newId;
  }

  function withdraw() external onlyOwner{
    payable(msg.sender).transfer(address(this).balance);
  }
}