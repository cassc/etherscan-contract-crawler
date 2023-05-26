// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IReverseRegistrar.sol";
import "./ERC721.sol";

contract MEV is ERC721, Ownable {
  string public PROVENANCE;
  bool provenanceSet;

  bool public paused;

  address immutable bricks = 0x6C06FF31156C4db4BE59D2ee4525b7380C9f09cA;
  address immutable ENSReverseRegistrar = 0x084b1c3C81545d370f3634392De611CaaBFf8148;

  mapping (uint256 => bool) public bricksTokenIDsUsed;

  constructor(
      string memory _name,
      string memory _symbol
  ) ERC721(_name, _symbol, 99) {}

  function flipPaused() external onlyOwner {
    paused = !paused;
  }

  function setProvenanceHash(string memory provenanceHash) public onlyOwner {
    require(!provenanceSet);
    PROVENANCE = provenanceHash;
    provenanceSet = true;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _setBaseURI(baseURI);
  }
  
  function mintWithBricks(uint256[] calldata bricksTokenIDs) public payable {
    require(!paused, "s");
    uint amountToMint = 0;
    for (uint i = 0; i<bricksTokenIDs.length; i++) {
      if (!bricksTokenIDsUsed[bricksTokenIDs[i]] && IERC721(bricks).ownerOf(bricksTokenIDs[i]) == msg.sender) {
        bricksTokenIDsUsed[bricksTokenIDs[i]] = true;
        amountToMint = amountToMint + 1;
      }
    }
    require(amountToMint > 0, "must have non zero mint amount");
    _safeMint(msg.sender, amountToMint);
  }

  function addReverseENSRecord(string memory name) external onlyOwner{
    IReverseRegistrar(ENSReverseRegistrar).setName(name);
  }

  function withdraw() external onlyOwner() {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function withdrawTokens(address tokenAddress) external onlyOwner() {
    IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
  }
}

// The High Table