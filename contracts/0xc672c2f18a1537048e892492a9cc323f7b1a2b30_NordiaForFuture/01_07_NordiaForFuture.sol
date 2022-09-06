// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NordiaForFuture is ERC721AQueryable, Ownable {
  string public baseURI;
  string public notRevealedUri;
  string public baseExtension = ".json";

  uint256 public maxSupply = 10021;
  bool public revealed = false;

  mapping (address => bool) public minters;

  constructor() ERC721A("NordiaForFuture", "NFF") {
    minters[msg.sender] = true;
  }

  // ====== Settings ======
  modifier onlyMinter() {
    require(minters[msg.sender], "Not allowed minter");
    _;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
  function _startTokenId() internal pure override returns (uint256){
    return 1;
  }
  //

  function mint(address _address, uint256 _mintAmount) external onlyMinter {
    // Amount Control
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "Max NFT limit exceeded");
    //

    _safeMint(_address, _mintAmount);
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

    if(revealed == false) return notRevealedUri;
    
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _toString(tokenId), baseExtension))
        : "";
  }

  // ====== Only Owner ======
  // Metadata 
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setNotRevealedUri(string memory _newNotRevealedUri) public onlyOwner {
    notRevealedUri = _newNotRevealedUri;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function reveal() public onlyOwner {
    revealed = true;
  }
  //

  // Minters
  function setMinter(address _address) external onlyOwner {
    require(!minters[_address], "Already added");
    minters[_address] = true;
  }

  function removeMinter(address _address) external onlyOwner {
    require(minters[_address], "Not minter");
    minters[_address] = false;
  }
  //
 
  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}