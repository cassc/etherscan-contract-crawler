// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract EvolutionApes is ERC721, Ownable, PaymentSplitter {
  using Strings for uint;
  using Counters for Counters.Counter;

  struct Sale {
      uint state;
      uint maxTokensPerAddress;
      uint price;
  }
  
  bool public revealed;
  string public notRevealedURI;
  string public baseURI;
  string public baseExtension;
  uint public maxSupply = 10010;
  Sale public sale;       
         
  mapping(address => bool) public isWhitelisted;
  mapping(address => uint8) public airdropAllowance;
    
  Counters.Counter private _tokenId;

  uint[] private _shares = [16, 16, 16, 16, 16, 16, 4];
  address[] private _team = [
    0xF16A786004F2E763b3e754c2245105f1e7AcA767,
    0x58B029B606D1d1311680813cCe39c4770f2f241C,
    0x7eDE5189FffC950f5A692B22C0311479D9B1bcF0,
    0xE139e34C1714a93701b7BCB2F7C0D174cdc1E2C6,
    0x0502EF00b5194d6899d96d027B0fb27A195F96b3,
    0xDA7d1A4C705B257ca18b8e820bff31b8a8CecD79,
    0xF22305ad50E7b36A81EF08d0995Ef3F3788b20F0
  ];

  constructor() 
    ERC721("Evolution Apes", "EA")
    PaymentSplitter(_team, _shares) {}
  
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
  function mintApe(uint _mintAmount) public payable {
    require(sale.state != 0, "Sale is not active");
    if (sale.state == 1) {
        require(isWhitelisted[msg.sender], "Only whitelisted users allowed during presale");
    }
    require(_mintAmount > 0, "You must mint at least 1 NFT");
    require(balanceOf(msg.sender) + _mintAmount <= sale.maxTokensPerAddress, "Max tokens per address exceeded for this wave");
    require(_tokenId.current() + _mintAmount <= maxSupply, "Max supply exceeded");
    require(msg.value >= sale.price * _mintAmount, "Please send the correct amount of ETH");
    for (uint i = 0; i < _mintAmount; i++) {
        _tokenId.increment();
        _safeMint(msg.sender, _tokenId.current());
    }
  }

  function gift(address _to, uint _mintAmount) public onlyOwner {
    require(_tokenId.current() + _mintAmount <= maxSupply, "Max supply exceeded");
    for (uint i = 0; i < _mintAmount; i++) {
      _tokenId.increment();
      _safeMint(_to, _tokenId.current());
    }
  }

  function claimAirdrop() public {
    uint _allowance = airdropAllowance[msg.sender];
    require(_allowance > 0, "You have no airdrops to claim");
    require(_tokenId.current() + _allowance <= maxSupply, "Max supply exceeded");
    for (uint i = 0; i < _allowance; i++) {
      _tokenId.increment();
      _safeMint(msg.sender, _tokenId.current());
    }
    airdropAllowance[msg.sender] = 0;
  }

  function tokenURI(uint tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(!revealed) {
        return notRevealedURI;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function totalSupply() public view returns(uint) {
    return _tokenId.current();
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

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedURI = _notRevealedURI;
  }
  
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function whitelist(address[] memory _users) public onlyOwner {
      for(uint i = 0; i < _users.length; i++) {
          isWhitelisted[_users[i]] = true;
      }
  }
  
  function unWhitelist(address[] memory _users) public onlyOwner {
     for(uint i = 0; i < _users.length; i++) {
          isWhitelisted[_users[i]] = false;
     }
  }

  function setAirdropAllowance(address[] memory _users, uint8[] memory _allowances) public onlyOwner {
      require(_users.length == _allowances.length, "Length mismatch");
      for(uint i = 0; i < _users.length; i++) {
          airdropAllowance[_users[i]] = _allowances[i];
      }
  }

  function setRevealed(bool _revealed) public onlyOwner() {
      revealed = _revealed;
  }

  // Payment splitter
  function totalBalance() public view returns(uint) {
        return address(this).balance;
  }
        
  function totalReceived() public view returns(uint) {
      return totalBalance() + totalReleased();
  }
    
  function etherBalanceOf(address _account) public view returns(uint) {
      return totalReceived() * shares(_account) / totalShares() - released(_account);
  }
  
  function release(address payable account) public override onlyOwner {
      super.release(account);
  }
  
  function withdraw() public {
      require(balanceOf(msg.sender) > 0, "No funds to withdraw");
      super.release(payable(msg.sender));
  }
}