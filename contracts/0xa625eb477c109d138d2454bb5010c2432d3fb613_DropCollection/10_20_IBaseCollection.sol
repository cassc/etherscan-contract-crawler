// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBaseCollection {
    /**
     * @dev Contract upgradeable initializer
     */
    function initialize(
        string memory,
        string memory,
        address,
        address
    ) external;

    /**
     * @dev part of Ownable
     */
    function transferOwnership(address) external;
}