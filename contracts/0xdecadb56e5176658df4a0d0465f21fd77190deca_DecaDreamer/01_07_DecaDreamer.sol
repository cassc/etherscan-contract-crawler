// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DecaDreamer is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 1 ether;
  uint256 public maxSupply = 5000;
  uint256 public MaxperWallet = 1;
  bool public paused = false;
  bool public revealed = true;
  constructor(
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721A("Deca Dreamer", "DDR") {
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
    require(!paused, "DDR: Dreams are currently on hold");
    uint256 supply = totalSupply();
    require(tokens > 0, "DDR: You need at least one dream");
    require(tokens <= MaxperWallet, "DDR: One dream per dreamer");
    require(supply + tokens <= maxSupply, "DDR: All dreams are gone, go fish on the markets");
    require(_numberMinted(_msgSender()) + tokens <= MaxperWallet, "DDR: Too many dreams in your purse already");
    require(msg.value >= cost * tokens, "DDR: You hear that empty sound? Refill your purse.");

      _safeMint(_msgSender(), tokens);
    
  }


  /// @dev use it for giveaway and mint for yourself
     function gift(uint256 _mintAmount, address destination) public onlyOwner nonReentrant {
    require(_mintAmount > 0, "You need at least one dream");
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "No more dreams for you, too many dreams already!");

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
      "ERC721AMetadata: I can't find that dream, have you checked with the Dream maker?"
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