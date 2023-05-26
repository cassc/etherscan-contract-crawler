// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract WSBSwappable is ERC721Enumerable, Ownable {

  event SwapTo(address indexed owner, uint256 indexed tokenId, uint256 nonce);
  event SwapFrom(address indexed owner, uint256 indexed tokenId, uint256 nonce);

  using SafeMath for uint256;
  using Counters for Counters.Counter;

  bool public swapActive = false;
  uint256 public swapPrice = 10000000000000000; // 0.01 ether;
  Counters.Counter private swapNonce;

  function toggleSwapActive() external onlyOwner  {
    swapActive = !swapActive;
  }

  function updateSwapPrice(uint256 price) external onlyOwner {
    swapPrice = price;
  }

  function swapTo(uint256 tokenId) external payable {
    require(tx.origin == msg.sender, "Swap: Can not be called using a contract.");
    require(swapActive, "Swap: Feature is not active.");
    require(ERC721.ownerOf(tokenId) == msg.sender, "Swap: Only owner can swap the token.");
    require(msg.value >= swapPrice, "Swap: Insufficient funds for swapping.");
    address owner = ERC721.ownerOf(tokenId);
    ERC721._safeTransfer(owner, address(this), tokenId, "");
    swapNonce.increment();
    emit SwapTo(owner, tokenId, swapNonce.current());
  }

  function swapFrom(address owner, uint256 tokenId) external onlyOwner {
    require(tx.origin == msg.sender, "Swap: Can not be called using a contract.");
    require(swapActive, "Swap: Feature is not active.");
    require(!ERC721._exists(tokenId) || ERC721.ownerOf(tokenId) == address(this), "Swap: This token is not swappable.");
    if (!ERC721._exists(tokenId)) {
      ERC721._safeMint(owner, tokenId);
    } else {
      ERC721._safeTransfer(address(this), owner, tokenId, "");
    }
    swapNonce.increment();
    emit SwapFrom(owner, tokenId, swapNonce.current());
  }

  function exists(uint256 tokenId) external view returns (bool) {
    return ERC721._exists(tokenId);
  }

}