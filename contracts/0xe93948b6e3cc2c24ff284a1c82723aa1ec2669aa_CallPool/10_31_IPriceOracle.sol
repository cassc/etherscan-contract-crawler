// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/************
@title IPriceOracle interface
@notice Interface for the Aave price oracle.*/
interface IPriceOracle {
  /***********
    @dev returns the asset price in wei
     */
  function getAssetPrice(address asset) external view returns (uint256);

  /***********
    @dev sets the asset price, in wei
     */
  function setAssetPrice(address asset, uint256 price) external;

  function getAssetVol(address asset) external view returns (uint256);
}