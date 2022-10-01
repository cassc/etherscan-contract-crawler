// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title FireCatRegistryProxy contract interface
 */
interface IFireCatRegistryProxy {
    /// IFireCatRegistryProxy

    /**
    * @notice user registration available switch.
    * @dev only owner.
    * @param switchOn_ switch side.
    */
    function setSwitchOn(bool switchOn_) external;

    /**
    * @notice user registration.
    * @dev set config to storage.
    * @param inviter_ inviter_address.
    */
    function userRegistration(address inviter_) external;

    /**
    * @notice user registration status.
    * @dev fetch data from storage.
    * @param user_ user_address.
     * @return status bool
    */
    function isRegistered(address user_) external view returns (bool);

    /**
    * @notice user's inviter.
    * @dev fetch data from storage.
    * @param user_ user_address.
     * @return inviter address
    */
    function getInviter(address user_) external view returns (address);

    /**
    * @notice inviter's users list.
    * @dev fetch data from storage.
    * @param inviter_ inviter_address.
     * @return users address list.
    */
    function getUsers(address inviter_) external view returns (address[] memory);

    /**
    * @notice num of total users.
    * @dev fetch data from storage.
     * @return uint256.
    */
    function getTotalUsers() external view returns (uint256);

    /**
    * @notice array of all users.
    * @dev fetch data from storage.
     * @return array of addresses.
    */
    function getUserArray() external view returns (address[] memory);
}