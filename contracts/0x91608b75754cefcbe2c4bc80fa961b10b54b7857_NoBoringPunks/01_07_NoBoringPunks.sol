// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NoBoringPunks is ERC721AQueryable, Ownable {
  string public baseURI;
  string public baseExtension = ".json";
  uint256 public maxSupply = 4999;
  uint256 public cost = 4000000000000000;
  bool public publicsale = false;

  constructor() ERC721A("No Boring Punks", "NBPK") {
  }

  // ====== Settings ======
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "cannot be called by a contract");
    _;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
  function _startTokenId() internal pure override returns (uint256){
    return 1;
  }
  //

  // ====== Mint Section ======
  function mint(uint256 _mintAmount) public payable callerIsUser {
    // Is publicsale active
    require(publicsale, "publicsale is not active");
    //

    // Amount control
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
    //

    // Payment control
    require(msg.value >= cost * _mintAmount, "insufficient funds");
    //

    _safeMint(msg.sender, _mintAmount);
  }

  function ownerMint(uint256 _mintAmount) public onlyOwner {
    // Amount controls
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
    //

    _safeMint(msg.sender, _mintAmount);
  }

  // ====== View ======
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
    
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _toString(tokenId), baseExtension))
        : "";
  }

  // ====== Only Owner ======
  function setPublicsale() public onlyOwner {
    publicsale = !publicsale;
  }

  // Metadata
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  //

  // Update Cost
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }
  //
 
  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}