// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library NativeOrERC20 {

  function balanceOf(address token, address owner) internal view returns (uint256) {
    if (isEth(token)) {
      return owner.balance;
    } else {
      return IERC20(token).balanceOf(owner);
    }
  }


  function isEth(address token) internal pure returns (bool) {
    return (token == address(0) || token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
  }

}