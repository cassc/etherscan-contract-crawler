// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAGIToken is IERC20{
  function lastEmissionTime() external view returns (uint256);

  function claimMasterRewards(uint256 amount) external returns (uint256 effectiveAmount);
  function masterEmissionRate() external view returns (uint256);
  function burn(uint256 amount) external;
}