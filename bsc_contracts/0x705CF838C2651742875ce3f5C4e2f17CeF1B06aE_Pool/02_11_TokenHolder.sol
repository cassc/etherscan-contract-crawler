// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title TokenHolder
 */
contract TokenHolder is Ownable {
  using SafeERC20 for IERC20;

  fallback() external payable {}
  receive() external payable {}

  /**
   * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
   * @param token The token contract address
   * @param user The user address
   * @param amount Number of tokens to be sent
   */
  function unlock(
    address token,
    address user,
    uint256 amount
  ) public virtual onlyOwner {
    IERC20(token).safeTransfer(user, amount);
  }

  function withdraw(address user, uint256 amount) public onlyOwner {
    payable(user).transfer(amount);
  }
}