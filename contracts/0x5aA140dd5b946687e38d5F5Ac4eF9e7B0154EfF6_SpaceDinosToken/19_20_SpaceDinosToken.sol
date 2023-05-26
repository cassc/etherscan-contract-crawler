// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import { ISpacePunksToken } from "./interfaces/ISpacePunksToken.sol";

contract SpaceDinosToken is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable, Pausable, PaymentSplitter, ReentrancyGuard {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  uint256 public constant TOKEN_LIMIT = 20000;
  string private __baseURI;

  bool public publicSale = false;
  bool public ownersGrant = true;
  uint256 private _maxTokensAtOnce;

  Counters.Counter private _tokenIds;

  uint256 private _tokenPrice;
  uint256[] private _teamShares = [50, 50];
  address[] private _team = [0x3515001548Cb3f93Dc5E3F3880D1f5ab2b0E07DB, 0xd240d8E59f1F49BCbBe4f0f1F711953F665aC551];
  address _spacePunksContractAddress = 0x45DB714f24f5A313569c41683047f1d49e78Ba07;

  constructor()
    PaymentSplitter(_team, _teamShares)
    ERC721("Space Dinos", "SDC")
  {
    setTokenPrice(0);
    setBaseURI("https://api.spacepunks.club/dinos/metadata/");
  }

  // Public sales
  function togglePublicSale() public onlyOwner {
    publicSale = !publicSale;
  }

  // _maxTokensAtOnce
  function maxTokensAtOnce() public view onlyOwner returns (uint256) {
    return _maxTokensAtOnce;
  }

  function setMaxTokensAtOnce(uint256 _count) public onlyOwner {
    _maxTokensAtOnce = _count;
  }

  // Minting
  function mintOneAsOwner(uint256 _tokenId) public payable whenNotPaused {
    require(ownersGrant, "Space Punk Owners grant period has ended");
    require(_tokenId <= 10000, "Token ID not allocated for Space Punk owners");
    require(msg.sender == ownerOfSpacePunk(_tokenId), "You must own the corresponding Space Punk to mint this token");
    _safeMint(msg.sender, _tokenId);
  }

  function mintMultipleAsOwner(uint256[] memory _ids) public payable nonReentrant whenNotPaused {
    require(ownersGrant, "Space Punk Owners grant period has ended");
    require(_ids.length > 0, "Provide an array of token IDs");
    require(balanceOfSpacePunkOwner(msg.sender) >= _ids.length, "You do not own the required number of Space Punk tokens");

    for(uint256 i = 0; i < _ids.length; i++) {
      mintOneAsOwner(_ids[i]);
    }
  }

  function mintTokens(uint256 _amount) public payable nonReentrant whenNotPaused {
    require(totalSupply().add(_amount) <= TOKEN_LIMIT, "Purchase would exceed max supply of tokens");
    require(publicSale, "Public sale must be active");
    require(_amount <= _maxTokensAtOnce, "Too many tokens at once");
    require(getTokenPrice().mul(_amount) == msg.value, "Insufficient funds to purchase");

    for(uint256 i = 0; i < _amount; i++) {
      _mintToken(msg.sender);
    }
  }

  function _mintToken(address _to) private {
    _tokenIds.increment();
    uint256 tokenId = (TOKEN_LIMIT - 10000).add(_tokenIds.current());
    _safeMint(_to, tokenId);
  }

  // Developer minting after the Owners Grant
  function devMint(uint256[] memory _ids) public payable nonReentrant onlyOwner {
    require(!ownersGrant, "Owners Grant must be over before you can mint");
    require(_ids.length > 0, "Provide an array of token IDs");

    for(uint256 i = 0; i < _ids.length; i++) {
      _safeMint(msg.sender, _ids[i]);
    }
  }

  // Token existence check
  function exists(uint256 _tokenId) public view returns (bool) {
    return _exists(_tokenId);
  }

  // Space Punks contract address
  function setSpacePunksContractAddress(address _contractAddress) public onlyOwner {
    _spacePunksContractAddress = _contractAddress;
  }

  // Required overrides from parent contracts
  function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  // _paused
  function togglePaused() public onlyOwner {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }

  // _tokenPrice
  function getTokenPrice() public view returns(uint256) {
    return _tokenPrice;
  }

  function setTokenPrice(uint256 _price) public onlyOwner {
    _tokenPrice = _price;
  }

  // Owners grant
  function setOwnersGrant(bool _value) public onlyOwner {
    ownersGrant = _value;
  }

  // SPC
  function ownerOfSpacePunk(uint _tokenId) public view returns (address) {
    ISpacePunksToken spacePunks = ISpacePunksToken(_spacePunksContractAddress);
    return spacePunks.ownerOf(_tokenId);
  }

  function balanceOfSpacePunkOwner(address _owner) public view returns (uint256) {
    ISpacePunksToken spacePunks = ISpacePunksToken(_spacePunksContractAddress);
    return spacePunks.balanceOf(_owner);
  }

  // Token URIs
  function _baseURI() internal override view returns (string memory) {
    return __baseURI;
  }

  function setBaseURI(string memory _value) public onlyOwner {
    __baseURI = _value;
  }
}