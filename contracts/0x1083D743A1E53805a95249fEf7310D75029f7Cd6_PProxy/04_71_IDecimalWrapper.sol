//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDecimalWrapper is IERC20 {
  event Deposit(address indexed dst, uint wad);
  event Withdrawal(address indexed src, uint wad);

  function deposit(uint256 _amount) external;
  function withdraw(uint256 _amount) external;

  function conversion() external view returns(uint256);
  function underlying() external view returns(address);
}