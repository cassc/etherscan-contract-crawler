// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;



interface ozIUpgradeableBeacon {

    /**
     * @dev Returns the queried version of the Storage Beacon
     */
    function storageBeacon(uint version_) external view returns(address);

    /**
     * @dev Stores a new version of the Storage Beacon
     */
    function upgradeStorageBeacon(address newStorageBeacon_) external;

    /**
     * @dev Designates a new authority for access control on certain methods
     * @param auth_ New RolesAuthority contract 
     */
    function setAuth(address auth_) external;

    /**
     * @notice Authorizing function
     * @dev To be queried in order to know if an user can call a certain function
     * @param user_ Entity to be queried in regards to authorization
     * @param target_ Contract where the function to be called is
     * @param functionSig_ Selector of function to be called
     * @return bool If user_ is authorized 
     */
    function canCall( 
        address user_,
        address target_,
        bytes4 functionSig_
    ) external view returns(bool);
}