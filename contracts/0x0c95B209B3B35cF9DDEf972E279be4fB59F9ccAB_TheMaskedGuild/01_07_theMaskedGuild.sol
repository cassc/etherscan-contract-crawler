// SPDX-License-Identifier: GPL-3.0

/*
              _                                          _       _   _                 
             | |                                        | |     | | (_)                
  _   _ _ __ | | ___ __   _____      ___ __    ___  ___ | |_   _| |_ _  ___  _ __  ___ 
 | | | | '_ \| |/ / '_ \ / _ \ \ /\ / / '_ \  / __|/ _ \| | | | | __| |/ _ \| '_ \/ __|
 | |_| | | | |   <| | | | (_) \ V  V /| | | | \__ \ (_) | | |_| | |_| | (_) | | | \__ \
  \__,_|_| |_|_|\_\_| |_|\___/ \_/\_/ |_| |_| |___/\___/|_|\__,_|\__|_|\___/|_| |_|___/

╔════════════════════════════════════════════════════════════════════════════╗
║           T H E   M A S K E D  G U I L D (c) Unknown Solutions             ║
║                   https://twitter.com/unknwnsolutions                      ║
╚════════════════════════════════════════════════════════════════════════════╝
╠═════════════════════════════════════╦══════════════════════════════════════╣
║ Artist    : 0xPetrarch              ║ Release Date : October 27, 2022      ║
║ Developer : 0xVolta                 ║ Supply       : 3318                  ║
║ BD        : 0xNigo                  ║ Drop No      : 1                     ║
╚═════════════════════════════════════╩══════════════════════════════════════╝
╔════════════════════════════════════════════════════════════════════════════╗
║  Born from the culture of an age-old renaissance, embedded with the        ║
║  technology of now.                                                        ║
╠════════════════════════════════════════════════════════════════════════════╣
║                 This is a retrospective of the future.                     ║
╚════════════════════════════════════════════════════════════════════════════╝
*/                                                                                                                                                                          

pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TheMaskedGuild is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.1 ether;
  uint256 public maxSupply = 3318;
  uint256 public MaxperWallet = 10;
  bool public paused = true;
  bool public revealed = true;

  constructor(
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721A("The Masked Guild", "GUILD") {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
      function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

  // public
  function mint(uint256 tokens) public payable nonReentrant {
    require(!paused, "GUILD: Contract is paused");
    uint256 supply = totalSupply();
    require(tokens > 0, "GUILD: Need to mint at least 1 NFT");
    require(tokens <= MaxperWallet, "GUILD: Max mint amount per tx exceeded");
    require(supply + tokens <= maxSupply, "GUILD: We Soldout");
    require(msg.value >= cost * tokens, "GUILD: insufficient funds");

      _safeMint(_msgSender(), tokens);
    
  }


  /// @dev use it for giveaway and mint for yourself
     function gift(uint256 _mintAmount, address destination) public onlyOwner nonReentrant {
    require(_mintAmount > 0, "Need to mint at least 1 NFT");
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "Max NFT limit exceeded");

      _safeMint(destination, _mintAmount);
    
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
      "ERC721AMetadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

    function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  //only owner
  function reveal(bool _state) public onlyOwner {
      revealed = _state;
  }
  
  function setMaxPerWallet(uint256 _limit) public onlyOwner {
    MaxperWallet = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }
    function setMaxsupply(uint256 _newsupply) public onlyOwner {
    maxSupply = _newsupply;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function withdraw() public payable onlyOwner nonReentrant {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}