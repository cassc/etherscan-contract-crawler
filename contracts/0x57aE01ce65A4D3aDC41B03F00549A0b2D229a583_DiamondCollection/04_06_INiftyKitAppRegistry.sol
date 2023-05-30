// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface INiftyKitAppRegistry {
    struct App {
        address implementation;
        bytes4 interfaceId;
        bytes4[] selectors;
        uint8 version;
    }

    struct Base {
        address implementation;
        bytes4[] interfaceIds;
        bytes4[] selectors;
        uint8 version;
    }

    /**
     * Get App Facet by app name
     * @param name app name
     */
    function getApp(bytes32 name) external view returns (App memory);

    /**
     * Get base Facet
     */
    function getBase() external view returns (Base memory);
}