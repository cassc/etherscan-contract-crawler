// SPDX-License-Identifier: MIT
//
//--------------------------
// 5F 30 78 30 30 6C 61 62
//--------------------------
//
// Token contract interface

pragma solidity ^0.8.4;

interface IToken {
  function        balanceOf(address account) external view returns (uint256);
  function        transfer(address to, uint256 amount) external returns (bool);
  function        transferFrom(address from,
                               address to,
                               uint256 amount
                               ) external returns (bool);
  function        approve(address spender, uint256 amount) external returns (bool);
  function        allowance(address owner, address spender) external view returns (uint256);
  function        grantManagerToContractInit(address account, uint256 amount) external;
  function        revokeManagerAfterContractInit(address account) external;
  function        mint(address to, uint256 amount) external;
}