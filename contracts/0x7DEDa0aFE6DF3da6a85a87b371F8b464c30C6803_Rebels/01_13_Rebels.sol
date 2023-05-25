// SPDX-License-Identifier: MIT

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@                                               @@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@                                                   @@@@@@@@@@@@@@@@@@@@@
@@@@@                                                     @@@@@@@@@@@@@@@@@@@@@@
@@@   ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@@@@
@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@            @@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@               @@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./render/IRebelsRenderer.sol";

contract Rebels is ERC721, Ownable {
  uint256 immutable public maxSupply;
  uint256 public totalSupply;
  address public rendererAddress;
  address public minterAddress;
  string public contractURI;
  bytes32 public provenanceHash;

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxSupply_
  ) ERC721(name_, symbol_) {
    maxSupply = maxSupply_;
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
    require(rendererAddress != address(0), "Renderer address unset");
    require(_exists(id), "URI query for nonexistent token");

    IRebelsRenderer renderer = IRebelsRenderer(rendererAddress);
    return renderer.tokenURI(id);
  }

  function mint(address to, uint256[] memory tokenIDs) external {
    require(msg.sender == minterAddress, "Minting from invalid address");

    for (uint256 i = 0; i < tokenIDs.length; ++i) {
      totalSupply += 1;
      _mint(to, tokenIDs[i]);
    }

    require(totalSupply <= maxSupply, "Trying to mint more than max supply");
  }

  function setRendererAddress(address rendererAddress_) external onlyOwner {
    rendererAddress = rendererAddress_;
  }

  function setMinterAddress(address minterAddress_) external onlyOwner {
    minterAddress = minterAddress_;
  }

  function setContractURI(string memory contractURI_) external onlyOwner {
    contractURI = contractURI_;
  }

  function setProvenanceHash(bytes32 provenanceHash_) external onlyOwner {
    provenanceHash = provenanceHash_;
  }

  function _beforeTokenTransfer(address from, address to, uint256 id) internal override {
    if (rendererAddress == address(0)) {
      return;
    }

    IRebelsRenderer renderer = IRebelsRenderer(rendererAddress);
    renderer.beforeTokenTransfer(from, to, id);
  }
}