// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

/**
 * @title Minting Ceremony
 */
interface IMintingCeremony {
  function allowance(address account)
    external
    view
    returns (uint256 remainingAllowance);

  function underlying() external view returns (address);

  function commit(
    address recipient,
    uint256 underlyingIn,
    uint256 floatOutMin
  ) external returns (uint256 floatOut);

  function mint() external;
}