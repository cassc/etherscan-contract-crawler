// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

interface StakeHouseAccessControls {
    function isCoreModuleLocked(address _module) external view returns (bool);
    function isProxyAdmin(address _module) external view returns (bool);
    function isCoreModule(address _module) external view returns (bool);
}