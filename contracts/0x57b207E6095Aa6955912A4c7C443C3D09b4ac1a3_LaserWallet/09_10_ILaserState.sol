// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

interface ILaserState {
    ///@dev upgradeSingleton() custom error.
    error LaserState__upgradeSingleton__notLaser();

    ///@dev initOwner() custom error.
    error LaserState__initOwner__walletInitialized();
    error LaserState__initOwner__addressWithCode();

    function changeOwner(address newOwner) external;

    function addLaserModule(address newModule) external;
}