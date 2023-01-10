// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Nidya is ERC721Enumerable, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  
  uint256 public constant maxSupply = 10000;
  uint256 public constant fixedMintAmount = 1;

  address public boxContract;

  bool public paused = true;

  constructor() ERC721("Nidya", "NIDYA") {
  }

  // Internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // Mint
  function mint(address _to, uint256 _id) external nonReentrant {
    // Is mint active
    require(!paused, "Mint is not active");

    // Amount controls
    uint256 supply = totalSupply();
    require(supply + fixedMintAmount <= maxSupply);
    //

    // Only allowed box contract can mint
    require(msg.sender == boxContract, "Not allowed minter");

    _safeMint(_to, _id);
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

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  // Metadata
  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  //

  // Box Contract
  function setBoxContract(address _addr) external onlyOwner {
    boxContract = _addr;
  }

  function togglePaused() external onlyOwner {
    paused = !paused;
  }
  //

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}