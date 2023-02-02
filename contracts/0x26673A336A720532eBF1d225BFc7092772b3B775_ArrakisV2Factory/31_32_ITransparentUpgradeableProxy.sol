// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ITransparentUpgradeableProxy {
    function changeAdmin(address newAdmin) external;

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable;
}