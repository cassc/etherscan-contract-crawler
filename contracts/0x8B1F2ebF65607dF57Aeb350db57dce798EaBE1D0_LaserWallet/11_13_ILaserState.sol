// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

interface ILaserState {
    ///@dev upgradeSingleton() custom error.
    error LaserState__upgradeSingleton__notLaser();

    ///@dev initOwner() custom errors.
    error LaserState__initOwner__walletInitialized();
    error LaserState__initOwner__invalidAddress();

    function singleton() external view returns (address);

    function owner() external view returns (address);

    function laserMasterGuard() external view returns (address);

    function laserRegistry() external view returns (address);

    function isLocked() external view returns (bool);

    function nonce() external view returns (uint256);

    ///@notice Restricted, can only be called by the wallet or module.
    function changeOwner(address newOwner) external;

    ///@notice Restricted, can only be called by the wallet.
    function addLaserModule(address newModule) external;
}