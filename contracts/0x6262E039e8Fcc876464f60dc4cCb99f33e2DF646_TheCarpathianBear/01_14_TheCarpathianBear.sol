// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TheCarpathianBear is ERC721Enumerable, Ownable {
  using Strings for uint256;
  using SafeMath for uint256;

  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.001 ether;
  uint256 public maxSupply = 5555;
  uint256 public maxMintAmount = 20;
  bool public paused = false;
  bool public revealed = false;
  string public notRevealedUri;
  string public _name = "The Carpathian Bear CB";
  string public _symbol = "CBV2";
  string public _initBaseURI = "ipfs://";
  string public _initNotRevealedUri = "ipfs://";

  constructor() ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function buyNFT(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount);
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
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

  //only the boss
  function privateMint(uint256 _mintAmount, address destination) public onlyOwner {
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "cannot mint 0");
    require(supply + _mintAmount <= maxSupply, "Max Supply Exceeded!");
    require(supply + _mintAmount <= 5555, "Cannot mint above 5555");

    for (uint256 i = 1; i <= _mintAmount; i++) {
        _safeMint(destination, supply + i);
    }
  }

  function revealNFTS(bool _state) public onlyOwner {
      revealed = _state;
  }
  
  function setNftCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setMaxBuyAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function pauseContract(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function withdraw(uint amount) public onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No ether left to withdraw");
    (bool success, ) = payable(msg.sender).call{value: amount}("");
    require(success, "Withdraw failed");
  }
}