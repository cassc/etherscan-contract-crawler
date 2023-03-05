// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILSDTokenLSETH is IERC20 {
  function getEthValue(uint256 _lsethAmount) external view returns (uint256);
  function getLsethValue(uint256 _ethAmount) external view returns (uint256);
  function getExchangeRate() external view returns (uint256);
  function mint(uint256 _ethAmount, address _to) external;
  function burn(uint256 _lsethAmount) external;
}