// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ToxicLakeMonsterToken is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable, Pausable, PaymentSplitter, ReentrancyGuard {
  using SafeMath for uint256;

  uint256 public constant TOKEN_LIMIT = 10000;

  bool public publicSale = false;
  uint256 private _maxTokensAtOnce;

  uint internal nonce = 0;
  uint[TOKEN_LIMIT] internal indices;

  uint256 private _tokenPrice;
  uint256[] private _teamShares = [50, 50];
  address[] private _team = [0xE2bfD7dA9C0962814DD44C9AD65CE6dB058b7a6f, 0x9114701Ba7C9a37C849Cce71FE98723d510e5DA6];

  mapping(address => uint8) public claimed;
  mapping(address => uint8) public presaleTokensCountByOwner;
  mapping(address => uint8) public pledgedTokensCountByOwner;
  uint256 public totalPledged;

  string private __baseURI;

  constructor()
    PaymentSplitter(_team, _teamShares)
    ERC721("Toxic Lake Monster", "TOX")
  {
    setBaseURI("https://api.toxiclakemonster.com/metadata/");
    setTokenPrice(69e15);
    setMaxTokensAtOnce(20);
  }

  // Pay now, mint later
  function spitHandshake(uint8 _count) public payable {
    require(getTokenPrice().mul(_count) == msg.value, "You need to pay the exact price");
    require(totalSupply().add(_count) <= TOKEN_LIMIT - totalPledged, "Purchase would exceed max supply of tokens");
    require(
      (_count + pledgedTokensCountByOwner[msg.sender] + claimed[msg.sender]) <= 5,
      "Each address can only purchase up to 5 tokens"
    );

    pledgedTokensCountByOwner[msg.sender] = pledgedTokensCountByOwner[msg.sender] + _count;
    totalPledged += uint256(_count);
  }

  function claim() public {
    require(pledgedTokensCountByOwner[msg.sender] > 0, "You do not have any tokens pledged");

    for(uint256 i = 0; i < pledgedTokensCountByOwner[msg.sender]; i++) {
      _mintToken(msg.sender);
    }

    claimed[msg.sender] += pledgedTokensCountByOwner[msg.sender];
    pledgedTokensCountByOwner[msg.sender] = 0;
  }

  // Presale for whitelisted addresses
  function presale(uint8 _amount) public payable nonReentrant whenNotPaused {
    require(!publicSale, "Pre-sale has already ended");
    require(totalSupply().add(_amount) <= TOKEN_LIMIT - totalPledged, "Purchase would exceed max supply of tokens");
    require(getTokenPrice().mul(_amount) == msg.value, "You need to pay the exact price");
    require((presaleTokensCountByOwner[msg.sender] + _amount) <= 5, "You can't mint more than 5 tokens during pre-sale");

    for(uint256 i = 0; i < _amount; i++) {
      _mintToken(msg.sender);
    }

    presaleTokensCountByOwner[msg.sender] = presaleTokensCountByOwner[msg.sender] + _amount;
  }

  // Minting
  function mintTokens(uint256 _amount) public payable nonReentrant whenNotPaused {
    require(totalSupply().add(_amount) <= TOKEN_LIMIT - totalPledged, "Purchase would exceed available supply of tokens");
    require(publicSale, "Public sale must be active");
    require(_amount <= _maxTokensAtOnce, "Too many tokens at once");
    require(getTokenPrice().mul(_amount) == msg.value, "You need to pay the exact price");

    for(uint256 i = 0; i < _amount; i++) {
      _mintToken(msg.sender);
    }
  }

  function _mintToken(address _to) private {
    uint _tokenID = randomIndex();
    _safeMint(_to, _tokenID);
  }

  // Developer minting
  function devMint(uint256 _amount) public nonReentrant onlyOwner {
    for(uint256 i = 0; i < _amount; i++) {
      _mintToken(msg.sender);
    }
  }

  // Pick a random index
  function randomIndex() internal returns (uint256) {
    uint256 totalSize = TOKEN_LIMIT - totalSupply();
    uint256 index = uint(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % totalSize;
    uint256 value = 0;

    if (indices[index] != 0) {
      value = indices[index];
    } else {
      value = index;
    }

    if (indices[totalSize - 1] == 0) {
      indices[index] = totalSize - 1;
    } else {
      indices[index] = indices[totalSize - 1];
    }

    nonce++;

    return value.add(1);
  }

  // Public sale
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

  // Token URIs
  function _baseURI() internal override view returns (string memory) {
    return __baseURI;
  }

  function setBaseURI(string memory _value) public onlyOwner {
    __baseURI = _value;
  }
}