// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14; 


import '@rari-capital/solmate/src/auth/authorities/RolesAuthority.sol';
import '@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol';
import '../interfaces/ethereum/ozIUpgradeableBeacon.sol';


/**
 * @title Middleware beacon proxy
 * @notice Holds the current version of the beacon and possible multiple versions
 * of the Storage beacon. It also hosts the control access methods for some actions
 */
contract ozUpgradeableBeacon is ozIUpgradeableBeacon, UpgradeableBeacon { 
    /// @dev Holds all the versions of the Storage Beacon
    address[] private _storageBeacons;

    RolesAuthority auth;

    event UpgradedStorageBeacon(address newStorageBeacon);
    event NewAuthority(address newAuthority);


    constructor(address impl_, address storageBeacon_) UpgradeableBeacon(impl_) {
        _storageBeacons.push(storageBeacon_);
    }


    /*///////////////////////////////////////////////////////////////
                        Storage Beacon methods
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ozIUpgradeableBeacon
    function storageBeacon(uint version_) external view returns(address) {
        return _storageBeacons[version_];
    }

    /// @inheritdoc ozIUpgradeableBeacon
    function upgradeStorageBeacon(address newStorageBeacon_) external onlyOwner {
        _storageBeacons.push(newStorageBeacon_);
        emit UpgradedStorageBeacon(newStorageBeacon_);
    }

    /*///////////////////////////////////////////////////////////////
                              Access Control
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ozIUpgradeableBeacon
    function setAuth(address auth_) external onlyOwner {
        auth = RolesAuthority(auth_);
        emit NewAuthority(auth_);
    }

    /// @inheritdoc ozIUpgradeableBeacon
    function canCall( 
        address user_,
        address target_,
        bytes4 functionSig_
    ) external view returns(bool) {
        bool isAuth = auth.canCall(user_, target_, functionSig_);
        return isAuth;
    }
}