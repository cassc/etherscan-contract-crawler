// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/utils/ERC721Holder.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";

contract Pigs is ERC721, Ownable, ERC721Holder {
  uint256 public constant _maxSupply = 10000;
  uint256 public totalSupply;
  bool public isSaleActive;

  constructor() ERC721("Pigs", "PIG") {}

  function allTokensOfOwner(address user) public view returns (uint256[] memory) {
    uint256[] memory allTokens = new uint256[](balanceOf(user));
    uint256 index = 0;
    for (uint16 i = 1; index < allTokens.length; i++) {
      if (ownerOf(i) == user) {
        allTokens[index++] = i;
      }
    }
    return allTokens;
  }

  function onERC721Received(address c, address to, uint256 tokenId, bytes memory) public virtual override returns (bytes4) {
    require(c != address(this), "You can't burn pigs! Moron!");
    require(IERC721(msg.sender).ownerOf(tokenId) == address(this), "Token not received");
    require(isSaleActive, "Sale is not active");
    require(totalSupply < _maxSupply, "Sale is over");
    _mint(to, ++totalSupply);
    return this.onERC721Received.selector;
  }

  function toggleSaleStatus() public onlyOwner {
    isSaleActive = !isSaleActive;
  }

  function withdraw() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function mintAsOwner(address to, uint8 amount) public onlyOwner {
    require(totalSupply + amount < _maxSupply, "Sold out");
    for (uint8 i = 0; i < amount; i++) {
      _mint(to, totalSupply + i + 1);
    }
    totalSupply += amount;
  }

  function _baseURI() internal pure override returns (string memory) {
    return "ipfs://QmXeBouRCQGgbDpCMz45iMDecnneXhyZUtBNT55czx57kb/";
  }
}