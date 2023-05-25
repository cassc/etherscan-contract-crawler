// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DegenToonz is ERC721, Ownable, ReentrancyGuard {
  using Strings for uint;
  using Counters for Counters.Counter;

  struct Sale {
      uint state; 
      uint maxTokensPerAddress;
      uint price;
  }

  bool public revealed;
  bool public isAirdropActive;
  string public notRevealedURI;
  string public baseURI;
  string public baseExtension;
  uint public maxPublicSupply = 8638;
  uint public maxSupply = 8888;
  uint public _reserveTokenId = maxPublicSupply;
  Sale public sale;
  
  mapping(address => bool) public isWhitelisted;
  mapping(address => uint8) public airdropAllowance;
  mapping(address => uint) public tokensMintedByAddress;

  Counters.Counter private _tokenId;

  constructor() ERC721("DEGEN TOONZ", "TOONZ") {}
  
   function totalSupply() public view returns(uint) {
     return _tokenId.current() + _reserveTokenId - maxPublicSupply;
   }

   function mintToon(uint _mintAmount) public payable {
    require(sale.state != 0, "Sale is not active");
    if (sale.state == 1) {
        require(isWhitelisted[msg.sender], "Only whitelisted users allowed during presale");
    }
    require(_mintAmount > 0, "You must mint at least 1 NFT");
    require(tokensMintedByAddress[msg.sender] + _mintAmount <= sale.maxTokensPerAddress, "Max tokens per address exceeded for this wave");
    require(_tokenId.current() + _mintAmount <= maxPublicSupply, "Max public supply exceeded");
    require(msg.value >= sale.price * _mintAmount, "Please send the correct amount of ETH");
    for (uint i = 0; i < _mintAmount; i++) {
        _tokenId.increment();
        _safeMint(msg.sender, _tokenId.current());
    }
    tokensMintedByAddress[msg.sender] += _mintAmount;
  }

  function gift(address _to, uint _mintAmount) public onlyOwner {
    require(_reserveTokenId + _mintAmount <= maxSupply, "Max reserve supply exceeded");
    for (uint i = 0; i < _mintAmount; i++) {
      _reserveTokenId++;
      _safeMint(_to, _reserveTokenId);
    }
  }

  function claimAirdrop() public {
    require(isAirdropActive, "Airdrop is inactive");
    uint _allowance = airdropAllowance[msg.sender];
    require(_allowance > 0, "You have no airdrops to claim");
    require(_reserveTokenId + _allowance <= maxSupply, "Max supply exceeded");
    for (uint i = 0; i < _allowance; i++) {
      _reserveTokenId++;
      _safeMint(msg.sender, _reserveTokenId);
    }
    airdropAllowance[msg.sender] = 0;
  }

  function tokenURI(uint tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    if(!revealed) {
        return notRevealedURI;
    }
    return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension)): "";
  }

  function setRevealed(bool _revealed) public onlyOwner() {
      revealed = _revealed;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedURI = _notRevealedURI;
  }

  function setBaseURI(string memory _baseURI, string memory _baseExtension) public onlyOwner {
    baseURI = _baseURI;
    baseExtension = _baseExtension;
  }

  function setSaleDetails(
      uint _state,
      uint _maxTokensPerAddress,
      uint _price
      ) public onlyOwner {
          sale.state = _state;
          sale.maxTokensPerAddress = _maxTokensPerAddress;
          sale.price = _price;
  } 
  
  function whitelist(address[] calldata _users) public onlyOwner {
      for (uint i = 0; i < _users.length; i++) {
          isWhitelisted[_users[i]] = true;
      }
  }
  
  function unWhitelist(address[] calldata _users) public onlyOwner {
     for(uint i = 0; i < _users.length; i++) {
          isWhitelisted[_users[i]] = false;
     }
  }

  function setAirdropActive(bool _state) public onlyOwner {
    isAirdropActive = _state;
  }
 
  function setAirdropAllowance(address[] calldata _users, uint8[] calldata _allowances) public onlyOwner {
      require(_users.length == _allowances.length, "Length mismatch");
      for(uint i = 0; i < _users.length; i++) {
          airdropAllowance[_users[i]] = _allowances[i];
      }
  }

  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success, "Withdrawal of funds failed");
  }
}