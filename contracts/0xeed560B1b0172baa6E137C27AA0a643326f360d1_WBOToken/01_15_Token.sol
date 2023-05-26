// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract WBOToken is ERC721, ERC721URIStorage, Pausable, Ownable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdCounter;

  string private _baseTokenURI;

  uint256 public price = 70000000000000000;

  uint256 public MAX_TOKENS = 12111;

  struct TokensByDeadline {
    uint256 deadline;
    uint256 max;
  }

  TokensByDeadline[] public tokensByDeadlines;

  mapping (address => bool) public whitelist;

  constructor() ERC721("The Winkybots", "WBOT") {}

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function setBaseTokenURI(string memory _uri) public onlyOwner {
    _baseTokenURI = _uri;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setPrice(uint _price) public onlyOwner {
    price = _price;
  }

  function addToWhitelist(address addr) public onlyOwner {
    whitelist[addr] = true;
  }
  
  function addListToWhitelist(address[] memory addrs) public onlyOwner {
    for (uint i = 0; i < addrs.length; i++) {
      whitelist[addrs[i]] = true;
    }
  }

  function deleteFromWhitelist(address addr) public onlyOwner {
    whitelist[addr] = false;
  }

  function addTokensByDeadlines(uint256 _deadline, uint256 _max) public onlyOwner {
    tokensByDeadlines.push(TokensByDeadline(_deadline, _max));
  }
  
  function deleteTokensByDeadlines(uint256 _index) public onlyOwner {
    delete tokensByDeadlines[_index];
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function mint(uint numberOfTokens) public payable {
    require(whitelist[msg.sender] || !paused(), "Address must be whitelisted OR Not paused");
    require(msg.value >= price.mul(numberOfTokens), "Ether value sent is not correct");
    mintTokens(msg.sender, numberOfTokens);
  }

  function mintTokens(address to, uint numberOfTokens) private {
    require(_tokenIdCounter.current().add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed MAX_TOKENS");
    
    for(uint i = 0; i < tokensByDeadlines.length; i++) {
      TokensByDeadline memory item = tokensByDeadlines[i];
      if(item.deadline > 0 && block.timestamp < item.deadline) {
        require(_tokenIdCounter.current().add(numberOfTokens) <= item.max, "Purchase would exceed period max");
      }
    }

    for(uint i = 0; i < numberOfTokens; i++) {
      uint256 mintIndex = _tokenIdCounter.current();
      if (mintIndex < MAX_TOKENS) {
	      _safeMint(to, mintIndex);
        _tokenIdCounter.increment();
      }
    }
  }

  function mintByOwner(address[] memory tos, uint[] memory amounts) public onlyOwner {
    for(uint i = 0; i < tos.length; i++) {
      mintTokens(tos[i], amounts[i]);
    }
  }
}