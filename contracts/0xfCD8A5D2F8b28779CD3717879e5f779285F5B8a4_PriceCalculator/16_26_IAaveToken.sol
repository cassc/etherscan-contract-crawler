//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.4;

interface IAaveToken {
  function scaledTotalSupply() external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function UNDERLYING_ASSET_ADDRESS() external view returns (address);

}