// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MoonBirdsVictorian is ERC721AQueryable, Ownable {
  string public baseURI;
  string public baseExtension = ".json";
  uint256 public maxSupply = 1000;
  uint256 public maxMintAmount = 2;

  bool public publicsale = false;
  mapping(address => uint256) public mintedBalance;

  constructor() ERC721A("Moon Birds Victorian", "MBVC") {
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

  // ====== public ======
  function mint(uint256 _mintAmount) public callerIsUser {
    // Is publicsale active
    require(publicsale, "publicsale is not active");
    //

    // Amount control
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
    require(mintedBalance[msg.sender] + _mintAmount <= maxMintAmount, "max NFT limit exceeded for this user");
    //

    // Increment balance before mint
    mintedBalance[msg.sender] += _mintAmount;
    //

    _safeMint(msg.sender, _mintAmount);
  }

  function ownerMint(address to, uint256 _mintAmount) public onlyOwner {
    // Amount Control
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
    //

    _safeMint(to, _mintAmount);
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

  function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
    maxMintAmount = _newMaxMintAmount;
  }
  //
 
  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}