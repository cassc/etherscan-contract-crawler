// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

interface ILaserRegistry {
    function isSingleton(address singleton) external view returns (bool);

    function isModule(address module) external view returns (bool);
}