pragma solidity ^0.8.1;

import "./IERC20.sol";

interface IWETH is IERC20 {
  function deposit() external payable;
  function withdraw(uint) external;
  function decimals() external view returns(uint8);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function transfer(address recipient, uint256 amount) external returns (bool);
}