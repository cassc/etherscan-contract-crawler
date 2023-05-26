// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Recoverable
 * @author artpumpkin
 * @notice Recovers stuck BNB or ERC20 tokens
 * @dev You can inhertit from this contract to support recovering stuck tokens or BNB
 */
contract Recoverable is Ownable {
  using SafeERC20 for IERC20;

  /**
   * @notice Recovers stuck ERC20 token in the contract
   * @param token_ An ERC20 token address
   * @param amount_ Amount to recover
   */
  function recoverERC20(address token_, uint256 amount_) external onlyOwner {
    IERC20 erc20 = IERC20(token_);
    require(erc20.balanceOf(address(this)) >= amount_, "invalid input amount");

    erc20.safeTransfer(owner(), amount_);
  }
}