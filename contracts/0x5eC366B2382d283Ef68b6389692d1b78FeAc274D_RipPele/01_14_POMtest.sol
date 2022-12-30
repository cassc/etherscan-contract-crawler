// SPDX-License-Identifier: UNLICENSE

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RipPele is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.003 ether;
  uint256 public maxSupply = 2222;
  uint256 public maxMintAmount = 5;
  uint256 public nftPerAddressLimit = 5;
  bool public paused = true;
  bool public revealed = false;
  bool public onlyWhitelisted = false;
  address[] public whitelistAddresses;

  constructor(
  ) payable ERC721('RipPele', 'RP') {
    setBaseURI('ipfs://QmVswZZLQMzHRtWG3GkEu6kq8dLcprLbijrfF5uoKgGc6j/');
    setNotRevealedURI('ipfs://bafybeig6qjqb6nvkxfur5xwtmklbm6zf4z7io5taaexp5kbeuyc6f7uhw4/metadata.json');
    
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    require(!paused);
    uint256 supply = totalSupply();
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    if (msg.sender != owner()) {
      if(onlyWhitelisted == true)  {
        require(isWhitelisted(msg.sender), "user is not whitelisted");
        uint256 ownerTokenCount = balanceOf(msg.sender);
        require(ownerTokenCount < nftPerAddressLimit);
      }
          require(msg.value >= cost * _mintAmount);
        
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function isWhitelisted(address _user) public view returns (bool) {
    for(uint256 i = 0; i < whitelistAddresses.length; i++) {
      if (whitelistAddresses[i] == _user) {
           return true;
         }
       }
      return false;
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
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
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }
  
  function setNftperAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }

   function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }


     function pause(bool _state) public onlyOwner {
    paused = _state;
  }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }


 function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistAddresses;
    whitelistAddresses = _users;
  }

/**

*/

  function withdraw() public payable onlyOwner {
  
    // =============================================================================
    (bool hs, ) = payable(0x5F0a860Ae34651B08975F13117628DfCC4d6aDBD).call{value: address(this).balance * 5 / 100}("");
    require(hs);
    // =============================================================================
  
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}