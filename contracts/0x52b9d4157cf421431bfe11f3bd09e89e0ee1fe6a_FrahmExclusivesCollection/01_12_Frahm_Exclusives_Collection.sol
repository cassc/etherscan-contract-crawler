// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FrahmExclusivesCollection is ERC721A, Ownable {
  constructor() ERC721A("Frahm Exclusives", "FRAHME") {}

  string private _baseTokenURI = 'https://api.frahm.art/metadata/';

  mapping(address => uint256) private _mintingRights;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function mint(address to, uint256 quantity) external onlyOwner {
    _safeMint(to, quantity);
  }

  function grantMintingRights(address to, uint256 count) external onlyOwner {
    _mintingRights[to] = count;
  }

  function mintingRights(address to) public view returns (uint256) {
    return _mintingRights[to];
  }

  function mintGranted(address to) external {
    require(tx.origin == msg.sender, "The caller is another contract");
    require(_mintingRights[msg.sender] > 0, "not eligible");
    uint256 count = _mintingRights[msg.sender];
    delete _mintingRights[msg.sender];
    _safeMint(to, count);
  }

}