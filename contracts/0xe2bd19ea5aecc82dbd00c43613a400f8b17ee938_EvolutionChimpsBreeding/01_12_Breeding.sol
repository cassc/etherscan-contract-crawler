// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract EvolutionChimpsBreeding is ERC721, Ownable {
  using Strings for uint;
  using Counters for Counters.Counter;

  struct Breeding {
      uint state;
  }
  
  bool public revealed;
  string public notRevealedURI;
  string public baseURI;
  string public baseExtension;

  uint public maxSupply = 2650;
  Breeding public breeding;
  
  mapping(address => uint8) public breedingAllowances;
    
  Counters.Counter private _tokenId;

  constructor() ERC721("Evolution Chimps", "EC") {}
  
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
  function breed() public {
    require(breeding.state != 0, "Breeding is not active");
    require(breedingAllowances[msg.sender] > 0, "You have no more apes left to breed with");

    uint8 breedAmount = breedingAllowances[msg.sender];
    require(_tokenId.current() + breedAmount <= maxSupply, "Maximum breeding limit reached");

    for (uint i = 0; i < breedAmount; i++) {
        breedingAllowances[msg.sender] -= 1;

        _tokenId.increment();
        _safeMint(msg.sender, _tokenId.current());
    }
  }

  function gift(address _to, uint _amount) public onlyOwner {
    require(_tokenId.current() + _amount <= maxSupply, "Maximum breeding limit reached");

    for (uint i = 0; i < _amount; i++) {
      _tokenId.increment();
      _safeMint(_to, _tokenId.current());
    }
  }

  function burnSingleToken(uint tokenId) public onlyOwner {
    _burn(tokenId);
  }

  function burnMultipleTokens(uint _amount) public onlyOwner {
    require(_tokenId.current() + _amount <= maxSupply, "Maximum breeding limit reached");

    for (uint i = 0; i < _amount; i++) {
      _tokenId.increment();
      _safeMint(msg.sender, _tokenId.current());
      _burn(_tokenId.current());
    }
  }

  function tokenURI(uint tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for non-existent token");
    
    if (!revealed) {
        return notRevealedURI;
    }

    string memory currentBaseURI = _baseURI();    
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
  }

  function totalSupply() public view returns(uint) {
    return _tokenId.current();
  }

  function setBreedingState(uint _state) public onlyOwner {
    breeding.state = _state;
  } 

  function deleteBreedingAllowance(address[] memory _users) public onlyOwner {
     for(uint i = 0; i < _users.length; i++) {
          breedingAllowances[_users[i]] = 0;
     }
  }

  function updateBreedingAllowances(address[] memory _users, uint8[] memory _allowances) public onlyOwner {
      require(_users.length == _allowances.length, "Length mismatch");
      
      for(uint i = 0; i < _users.length; i++) {
          breedingAllowances[_users[i]] = _allowances[i];
      }
  }

  function setRevealed(bool _revealed) public onlyOwner() {
      revealed = _revealed;
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

  function setMaxSupply(uint _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

}