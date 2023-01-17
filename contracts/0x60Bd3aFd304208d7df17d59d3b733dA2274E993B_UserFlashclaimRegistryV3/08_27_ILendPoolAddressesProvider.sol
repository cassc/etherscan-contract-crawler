// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface ILendPoolAddressesProvider {
  function getLendPoolLoan() external view returns (address);
}