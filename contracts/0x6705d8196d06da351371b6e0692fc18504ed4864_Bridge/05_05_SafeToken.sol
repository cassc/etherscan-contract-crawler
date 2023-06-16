// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Token {
  function balanceOf(address wallet) external view returns (uint);
  function approve(address spender, uint amount) external;
  function transfer(address to, uint amount) external;
  function transferFrom(address from, address to, uint amount) external;
}

library SafeToken {
  function approve(address token, address spender, uint amount) internal {
    require(Token(token).balanceOf(address(this)) >= amount, 'SafeToken: insufficient balance for approve');
    Token(token).approve(spender, amount);
  }

  function move(address token, address from, address to, uint amount) internal returns (uint) {
    require(Token(token).balanceOf(from) >= amount, 'SafeToken: insufficient balance for move');

    uint before = Token(token).balanceOf(to);
    if (from == address(this)) {
      Token(token).transfer(to, amount);
    } else {
      Token(token).transferFrom(from, to, amount);
    }
    return Token(token).balanceOf(to) - before;
  }
}