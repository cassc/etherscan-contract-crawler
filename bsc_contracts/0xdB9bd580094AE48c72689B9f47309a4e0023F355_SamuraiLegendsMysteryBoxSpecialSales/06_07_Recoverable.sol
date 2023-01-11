// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Recoverable
 * @author Leo
 * @notice Recovers stucked BNB or ERC20 tokens
 * @dev You can inhertit from this contract to support recovering stucked tokens or BNB
 */
contract Recoverable is Ownable {
  /**
   * @notice Recovers stucked BNB in the contract
   */
  function recoverBNB(uint256 amount) external onlyOwner {
    require(address(this).balance >= amount, "Recoverable::recoverBNB: invalid input amount");
    (bool success, ) = payable(owner()).call{ value: amount }("");
    require(success, "Recoverable::recoverBNB: recover failed");
  }

  /**
   * @notice Recovers stucked ERC20 token in the contract
   * @param token An ERC20 token address
   */
  function recoverERC20(address token, uint256 amount) external onlyOwner {
    IERC20 erc20 = IERC20(token);
    require(erc20.balanceOf(address(this)) >= amount, "Recoverable::recoverERC20: invalid input amount");

    erc20.transfer(owner(), amount);
  }
}