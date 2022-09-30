//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

abstract contract Payable is Ownable {
  /**
   * @dev Sends entire balance to contract owner.
   */
  function withdrawAll() external {
    payable(owner()).transfer(address(this).balance);
  }

    /**
   * @dev Sends entire balance of a given ERC20 token to contract owner.
   */
  function withdrawAllERC20(IERC20 _erc20Token) external virtual {
    _erc20Token.transfer(owner(), _erc20Token.balanceOf(address(this)));
  }
}