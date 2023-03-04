// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

abstract contract Proxiable {
    /// @dev Complying with EIP-1822: Universal Upgradeable Proxy Standard (UUPS)
    /// @dev See https://eips.ethereum.org/EIPS/eip-1822.
    function proxiableUUID() virtual external view returns (bytes32);

    struct ProxiableSlot {
        address implementation;
        address proxy;
    }

    function __implementation() internal view returns (address) {
        return __proxiable().implementation;
    }

    function __proxy() internal view returns (address) {
        return __proxiable().proxy;
    }

    function __proxiable() internal pure returns (ProxiableSlot storage proxiable) {
        assembly {
            // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
            proxiable.slot := 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
        }
    }
}