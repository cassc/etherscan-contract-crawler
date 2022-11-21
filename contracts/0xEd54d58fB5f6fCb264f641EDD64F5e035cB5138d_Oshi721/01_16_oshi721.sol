// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721Enumerable, ERC721, IERC721 } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { DefaultOperatorFilterer } from "./royalty/DefaultOperatorFilterer.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

// Oshi + Pellar + LightLink 2022

contract Oshi721 is ERC721Enumerable, DefaultOperatorFilterer, Ownable {
  bool public saleActive;
  uint256 public price = 15 ether;
  string public baseURI;

  constructor() ERC721("Oshi721", "Oshi") {}

  /* View */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
  }

  /* User */
  function mint() external payable {
    require(msg.sender == tx.origin, "Not allowed");
    require(saleActive, "Sale not active");
    require(totalSupply() < 48, "Sold out");
    require(msg.value >= price, "Not enough ETH");

    _safeMint(msg.sender, totalSupply());
  }

  /* Admin */
  function toggleSale(bool _status) external onlyOwner {
    saleActive = _status;
  }

  function changePrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function changeTokenURI(string calldata _baseURI) external onlyOwner {
    baseURI = _baseURI;
  }

  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  /* Royalty */
  function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}