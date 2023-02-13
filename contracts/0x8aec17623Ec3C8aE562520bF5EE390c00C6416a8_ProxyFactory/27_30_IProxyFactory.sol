// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


import './IStorageBeacon.sol';

interface IProxyFactory {

    /**
     * @notice Creator the user account and its correspondant Gelato task
     * @dev Creates the proxy where users get their ETH sent to, and calls for 
     * the generation of the Gelato task for each one.
     * @param acc_ Account details attached to each user
     * @return address The address of the account/proxy
     */
    function createNewProxy(
        IStorageBeacon.AccountConfig calldata acc_
    ) external returns(address);

    /// @dev Initializer
    function initialize() external;

    /**
     * @dev Gets the owner of Factory
     * @return address Owner
     */
    function getOwner() external view returns(address);

    /**
     * @dev Changes the owner of the Factory
     * @param newOwner_ New Owner
     */
    function changeOwner(address newOwner_) external;
}