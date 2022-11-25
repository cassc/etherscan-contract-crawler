// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface Proxiable {
    /// @dev Complying with EIP-1822: Universal Upgradable Proxy Standard (UUPS)
    /// @dev See https://eips.ethereum.org/EIPS/eip-1822.
    function proxiableUUID() external pure returns (bytes32);
}