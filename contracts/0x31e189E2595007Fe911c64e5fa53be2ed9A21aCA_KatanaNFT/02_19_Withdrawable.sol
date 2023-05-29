// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './Ownable.sol';

abstract contract Withdrawable is Ownable {
  function _withdraw(address token, address to) internal {
    require(to != address(0), 'Withdrawable: cannot withdraw to zero address');

    if (token != address(0)) {
      IERC20 token_ = IERC20(token);

      uint256 balance = token_.balanceOf(address(this));
      require(balance > 0, 'Withdrawable: cannot withdraw 0 ERC20');

      token_.transfer(to, balance);
    } else {
      uint256 balance = address(this).balance;
      require(balance > 0, 'Withdrawable: cannot withdraw 0 ETH');

      payable(to).transfer(balance);
    }
  }

  function withdraw() external onlyOwner {
    _withdraw(address(0), msg.sender);
  }

  function withdraw(address to) external onlyOwner {
    _withdraw(address(0), to);
  }

  function withdrawToken(address token) external onlyOwner {
    require(
      token != address(0),
      'Withdrawable: zero address is not an ERC20 token'
    );

    _withdraw(token, msg.sender);
  }

  function withdrawToken(address token, address to) external onlyOwner {
    require(
      token != address(0),
      'Withdrawable: zero address is not an ERC20 token'
    );

    _withdraw(token, to);
  }
}