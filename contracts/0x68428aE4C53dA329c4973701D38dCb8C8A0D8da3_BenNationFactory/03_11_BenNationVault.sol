// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {SafeERC20, IERC20} from "./oz/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "./oz/access/Ownable.sol";

contract BenNationVault is Ownable {
  using SafeERC20 for IERC20;

  function safeTransfer(IERC20 _token, address _to, uint _amount) external onlyOwner {
    _token.safeTransfer(_to, _amount);
  }
}