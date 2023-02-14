// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title ISturdyAPRDataProvider
 * @author Sturdy
 * @notice APR Data provider.
 **/
interface ISturdyAPRDataProvider {
  function updateAPR(
    address _borrowReserve,
    uint256 _yield,
    uint256 _totalSupply
  ) external;
}