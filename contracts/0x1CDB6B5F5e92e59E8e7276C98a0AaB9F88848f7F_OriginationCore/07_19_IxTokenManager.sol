//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface IxTokenManager {
    /**
     * @dev Add a manager to an xAsset fund
     */
    function addManager(address manager, address fund) external;

    /**
     * @dev Remove a manager from an xAsset fund
     */
    function removeManager(address manager, address fund) external;

    /**
     * @dev Check if an address is a manager for a fund
     */
    function isManager(address manager, address fund)
        external
        view
        returns (bool);

    /**
     * @dev Set revenue controller
     */
    function setRevenueController(address controller) external;

    /**
     * @dev Check if address is revenue controller
     */
    function isRevenueController(address caller) external view returns (bool);
}