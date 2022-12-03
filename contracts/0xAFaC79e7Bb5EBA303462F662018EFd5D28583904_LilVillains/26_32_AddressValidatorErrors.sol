// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Invalid address sent. It doesn't implements the require interface
// @param addressSent sent address.
// @param interfaceRequired required interface.
error InterfaceIsNotImplemented(address addressSent, bytes4 interfaceRequired);
// Invalid address sent. Needed a not zero address
error ZeroAddressNotSupported();