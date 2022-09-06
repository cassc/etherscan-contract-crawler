// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

/// @dev Common contract exceptions

/// @dev throws if zero address is provided
error ZeroAddressException();

/// @dev throws if non implemented method was called
error NotImplementedException();

/// @dev throws if expected contract but provided non-contract address
error AddressIsNotContractException(address);

/// @dev throws if token has no balanceOf(address) method, or this method reverts
error IncorrectTokenContractException();

/// @dev throws if token has no priceFeed in PriceOracle
error IncorrectPriceFeedException();

/// @dev throw if caller is not CONFIGURATOR
error CallerNotConfiguratorException();

/// @dev throw if caller is not PAUSABLE ADMIN
error CallerNotPausableAdminException();

/// @dev throw if caller is not UNPAUSABLE ADMIN
error CallerNotUnPausableAdminException();