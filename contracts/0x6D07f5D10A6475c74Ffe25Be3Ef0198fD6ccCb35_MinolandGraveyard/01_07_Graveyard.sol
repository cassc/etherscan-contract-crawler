// SPDX-License-Identifier: MIT
// Creator: https://cojodi.com
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "hardhat/console.sol";

contract MinolandGraveyard is IERC721Receiver, Ownable {
  uint256 public sellPrice = 0.00001 ether;

  event TokenSold(address indexed seller, address tokenAddress, uint256 tokenId, uint256 price);

  // sell function
  function onERC721Received(
    address,
    address from_,
    uint256 tokenId_,
    bytes calldata data_
  ) external override returns (bytes4) {
    address erc721Addr = abi.decode(data_, (address));
    payable(from_).transfer(sellPrice);

    emit TokenSold(from_, erc721Addr, tokenId_, sellPrice);

    return this.onERC721Received.selector;
  }

  function setSellPrice(uint256 sellPrice_) external onlyOwner {
    sellPrice = sellPrice_;
  }

  function withdrawTokens(
    address receiver_,
    address[] calldata tokenAddresses_,
    uint256[] calldata tokenIds_
  ) external onlyOwner {
    for (uint256 i = 0; i < tokenIds_.length; ++i) {
      uint256 tokenId = tokenIds_[i];
      address tokenAddr = tokenAddresses_[i];
      IERC721(tokenAddr).transferFrom(address(this), receiver_, tokenId);
    }
  }

  function withdraw(address receiver_, uint256 amount_) external onlyOwner {
    payable(receiver_).transfer(amount_);
  }

  // solhint-disable-next-line
  function deposit() external payable {}
}