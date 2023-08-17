// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Reclaimer
 * @author Protofire
 * @dev Allows owner to claim ERC20 tokens ot ETH sent to this contract.
 */
abstract contract Claimer is Ownable {
  using SafeERC20 for IERC20;

  /**
   * @dev send all token balance of an arbitrary erc20 token
   * in the contract to another address
   * @param token token to reclaim
   * @param _to address to send eth balance to
   */
  function claimToken(IERC20 token, address _to) external onlyOwner {
    uint256 balance = token.balanceOf(address(this));
    token.safeTransfer(_to, balance);
  }

  /**
   * @dev send all eth balance in the contract to another address
   * @param _to address to send eth balance to
   */
  function claimEther(address payable _to) external onlyOwner {
    require(_to != address(0), "transfer to the zero address");
    (bool sent, ) = _to.call{value: address(this).balance}("");
    require(sent, "Failed to send Ether");
  }
}