// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface IBTSOwnerManager {
    /**
       @notice Adding another Owner.
       @dev Caller must be an Owner of BTP network
       @param _owner    Address of a new Owner.
    */
    function addOwner(address _owner) external;

    /**
       @notice Removing an existing Owner.
       @dev Caller must be an Owner of BTP network
       @dev If only one Owner left, unable to remove the last Owner
       @param _owner    Address of an Owner to be removed.
    */
    function removeOwner(address _owner) external;

    /**
       @notice Checking whether one specific address has Owner role.
       @dev Caller can be ANY
       @param _owner    Address needs to verify.
    */
    function isOwner(address _owner) external view returns (bool);

    /**
       @notice Get a list of current Owners
       @dev Caller can be ANY
       @return      An array of addresses of current Owners
    */

    function getOwners() external view returns (address[] memory);

}