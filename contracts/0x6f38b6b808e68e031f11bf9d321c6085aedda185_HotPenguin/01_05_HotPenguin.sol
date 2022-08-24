// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import '@openzeppelin/contracts/access/Ownable.sol';
import 'erc721a/contracts/ERC721A.sol';

contract HotPenguin is Ownable, ERC721A {
  string public baseURI = 'ipfs://bafybeiczaeth4i4uakrrr2this6hvkkfzlo3h7h7lmlyzupgfkurg3uvfq/';
  uint256 public maxSupply = 4000;
  uint256 constant maxFreeSupply = 3000;
  uint256 constant maxPerWallet = 2;
  uint256 constant unitPrice = 0.008 ether;

  constructor() ERC721A('HotPenguin', 'HOPE') {
    _mintERC2309(msg.sender, maxSupply / 10);
  }

  function mint(uint64 quantity) external payable {
    uint256 nextSupply = _nextTokenId() - _startTokenId() + quantity;
    require(nextSupply <= maxSupply, '0');
    require(nextSupply <= maxFreeSupply || (quantity * unitPrice) <= msg.value, '1');
    require((_numberMinted(msg.sender) + quantity) <= maxPerWallet, '2');
    _mint(msg.sender, quantity);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 0;
  }

  function setBaseURI(string calldata __baseURI) external onlyOwner {
    baseURI = __baseURI;
  }

  function reduceMaxSupplyTo(uint256 _maxSupply) external onlyOwner {
    require(_maxSupply < maxSupply);
    maxSupply = _maxSupply;
  }

  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
}