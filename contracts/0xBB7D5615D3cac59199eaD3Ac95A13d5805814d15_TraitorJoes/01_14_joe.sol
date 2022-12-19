// SPDX-License-Identifier: MIT

/*

https://t.me/TraitorJoeCards


▄▄▄█████▓ ██▀███   ▄▄▄       ██▓▄▄▄█████▓ ▒█████   ██▀███      ▄▄▄██▀▀▀▒█████  ▓█████   ██████ 
▓  ██▒ ▓▒▓██ ▒ ██▒▒████▄    ▓██▒▓  ██▒ ▓▒▒██▒  ██▒▓██ ▒ ██▒      ▒██  ▒██▒  ██▒▓█   ▀ ▒██    ▒ 
▒ ▓██░ ▒░▓██ ░▄█ ▒▒██  ▀█▄  ▒██▒▒ ▓██░ ▒░▒██░  ██▒▓██ ░▄█ ▒      ░██  ▒██░  ██▒▒███   ░ ▓██▄   
░ ▓██▓ ░ ▒██▀▀█▄  ░██▄▄▄▄██ ░██░░ ▓██▓ ░ ▒██   ██░▒██▀▀█▄     ▓██▄██▓ ▒██   ██░▒▓█  ▄   ▒   ██▒
  ▒██▒ ░ ░██▓ ▒██▒ ▓█   ▓██▒░██░  ▒██▒ ░ ░ ████▓▒░░██▓ ▒██▒    ▓███▒  ░ ████▓▒░░▒████▒▒██████▒▒
  ▒ ░░   ░ ▒▓ ░▒▓░ ▒▒   ▓▒█░░▓    ▒ ░░   ░ ▒░▒░▒░ ░ ▒▓ ░▒▓░    ▒▓▒▒░  ░ ▒░▒░▒░ ░░ ▒░ ░▒ ▒▓▒ ▒ ░
    ░      ░▒ ░ ▒░  ▒   ▒▒ ░ ▒ ░    ░      ░ ▒ ▒░   ░▒ ░ ▒░    ▒ ░▒░    ░ ▒ ▒░  ░ ░  ░░ ░▒  ░ ░
  ░        ░░   ░   ░   ▒    ▒ ░  ░      ░ ░ ░ ▒    ░░   ░     ░ ░ ░  ░ ░ ░ ▒     ░   ░  ░  ░  
            ░           ░  ░ ░               ░ ░     ░         ░   ░      ░ ░     ░  ░      ░  
 */                                                                                              

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TraitorJoes is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.001 ether;
  uint256 public maxSupply = 1942;
  uint256 public maxMintAmountPerTX = 35;
  bool public paused = true;
  bool public revealed = true;
  string public notRevealedUri;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmountPerTX);
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

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmountPerTX(uint256 _newmaxMintAmountPerTX) public onlyOwner {
    maxMintAmountPerTX = _newmaxMintAmountPerTX;
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
 
 function withdraw() public payable onlyOwner {
    (bool hs, ) = payable(0x1B79d6209EF081e8EC4F4efCD16e0B5013731173).call{value: address(this).balance * 5 / 100}("");
    require(hs);

    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}