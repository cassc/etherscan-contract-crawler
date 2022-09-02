// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import '@openzeppelin/contracts/access/ownable.sol';
import 'erc721a/contracts/ERC721A.sol';

contract XiaoYan is Ownable, ERC721A {
  string public baseURI = 'ipfs://bafybeifgz4dphx7l3txixeeszghwnc7dyklffj3r3vnvn7ucnxab7tyzpy/';

  bool public isMintOpen = false;

  uint256 public immutable unitPrice = 0.002 ether;

  uint256 public immutable maxSupply = 2500;

  uint256 public immutable maxWalletSupply = 20;

  uint256 public immutable maxWalletFreeSupply = 2;

  constructor() ERC721A('XiaoYan', 'XY') {
    _mint(msg.sender, 1);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function startTokenId() external pure returns (uint256) {
    return _startTokenId();
  }

  function nextTokenId() external view returns (uint256) {
    return _nextTokenId();
  }

  function numberMinted(address owner) external view returns (uint256) {
    return _numberMinted(owner);
  }

  function mint(uint256 quantity) external payable {
    unchecked {
      require(isMintOpen, '0');

      uint256 currentSupply = _nextTokenId() - 1;
      require((currentSupply + quantity) <= maxSupply, '1');

      uint256 walletSupply = _numberMinted(msg.sender);
      require((walletSupply + quantity) <= maxWalletSupply, '2');

      uint256 walletFreeSupply = walletSupply > maxWalletFreeSupply
        ? maxWalletFreeSupply
        : walletSupply;
      uint256 freeQuantity = maxWalletFreeSupply > walletFreeSupply
        ? maxWalletFreeSupply - walletFreeSupply
        : 0;
      require(
        msg.value >= unitPrice * (quantity > freeQuantity ? quantity - freeQuantity : 0),
        '3'
      );
    }

    _mint(msg.sender, quantity);
  }

  function setBaseURI(string calldata uri) external onlyOwner {
    baseURI = uri;
  }

  function setIsMintOpen(bool _isMintOpen) external onlyOwner {
    isMintOpen = _isMintOpen;
  }

  function withdraw(address to) external onlyOwner {
    payable(to).transfer(address(this).balance);
  }
}