// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IUUPS {
    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes calldata data) external;
}