// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPrometheans {
  function mint() external payable;

  function mintTo(address to) external payable;

  function currentEmber() external view returns (uint256);
}

contract PrometheansSafeMint is Ownable, IERC721Receiver {
  IPrometheans public prometheans;

  constructor(address _prometheans) {
    prometheans = IPrometheans(_prometheans);
    IERC721(_prometheans).setApprovalForAll(msg.sender, true);
  }

  /**
   * @dev Mint a Prometheans NFT and send to the contract. This is a donation to the owner of the contract.
   * @param maxEmber Revert if the current ember is higher than this value.
   */
  function mint(uint256 maxEmber) external payable {
    require(prometheans.currentEmber() <= maxEmber, "too hot");
    prometheans.mint{value: msg.value}();
  }

  /**
   * @dev Mint a Prometheans NFT and send to address
   * @param to Address to send the NFT to.
   * @param maxEmber Revert if the current ember is higher than this value.
   */
  function mintTo(uint256 maxEmber, address to) external payable {
    require(prometheans.currentEmber() <= maxEmber, "too hot");
    prometheans.mintTo{value: msg.value}(to);
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function withdrawERC721(address token, uint256 tokenId) external onlyOwner {
    IERC721(token).safeTransferFrom(address(this), owner(), tokenId);
  }

  function approveERC20(address token, bool approved) external onlyOwner {
    IERC20(token).approve(owner(), approved ? type(uint256).max : 0);
  }

  function withdrawERC20(address token, uint256 amount) external onlyOwner {
    IERC20(token).transfer(owner(), amount);
  }
}