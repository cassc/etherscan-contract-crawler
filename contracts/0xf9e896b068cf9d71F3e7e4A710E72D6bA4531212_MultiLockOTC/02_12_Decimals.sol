// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

/// @dev this interface is a critical addition that is not part of the standard ERC-20 specifications
/// @dev this is required to do the calculation of the total price required, when pricing things in the payment currency
/// @dev only the payment currency is required to have a decimals impelementation on the ERC20 contract, otherwise it will fail
interface Decimals {
  function decimals() external view returns (uint256);
}