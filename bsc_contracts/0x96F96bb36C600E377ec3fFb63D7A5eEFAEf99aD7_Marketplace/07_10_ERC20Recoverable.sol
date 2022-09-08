// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
@title ERC20 Recoverable
@author Leo
@notice Recovers stuck ERC20 tokens
@dev You can inhertit from this contract to support recovering stuck ERC20 tokens
*/
contract ERC20Recoverable is Ownable {
  /**
    @notice Recovers stuck ERC20 token in the contract
    @param token An ERC20 token address
    */
  function recoverERC20(IERC20 token, uint256 amount) external onlyOwner {
    require(token.balanceOf(address(this)) >= amount, "invalid input amount");

    token.transfer(owner(), amount);
  }
}