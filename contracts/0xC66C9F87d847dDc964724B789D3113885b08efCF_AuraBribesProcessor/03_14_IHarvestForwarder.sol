// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;
pragma experimental ABIEncoderV2;

interface IHarvestForwarder {
  function distribute(
    address token,
    uint256 amount,
    address beneficiary
  ) external;
  function badger_tree() external view returns(address);
}