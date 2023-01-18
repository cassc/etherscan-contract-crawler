//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SafeWithdrawable is Ownable {

  function recoverERC721(
    address tokenAddress, 
    address dst, 
    uint256 tokenId
  ) public 
    onlyOwner
  {
    IERC721(tokenAddress).safeTransferFrom(address(this), dst, tokenId, '0x');
  }

  function recoverERC1155(
    address tokenAddress, 
    address dst, 
    uint256 tokenId,
    uint256 amount
  ) public 
    onlyOwner
  {
    IERC1155(tokenAddress).safeTransferFrom(address(this), dst, tokenId, amount, '0x');
  }

  function recoverERC20(
    address tokenAddress,
    address dst,
    uint256 amount
  ) public
    onlyOwner
  {
    IERC20(tokenAddress).transferFrom(address(this), dst, amount);
  }

  function recoverETH(
    address payable dst,
    uint256 amount
  ) public
    onlyOwner
  {
    dst.transfer(amount);
  }
}