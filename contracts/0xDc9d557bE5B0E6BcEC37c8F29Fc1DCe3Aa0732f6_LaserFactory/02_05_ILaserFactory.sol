// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

import "../proxies/LaserProxy.sol";

/**
 * @title  LaserFactory
 *
 * @notice Factory that creates new Laser proxies, and has helper methods.
 *
 * @dev    This interface has all events, errors, and external function for LaserFactory.
 */
interface ILaserFactory {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event LaserCreated(address laser);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error LF__constructor__invalidSingleton();

    error LF__createProxy__creationFailed();

    error LF__deployProxy__create2Failed();

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    function singleton() external view returns (address);

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
     *
     * @param initializer   Payload for message call sent to new proxy contract.
     * @param saltNonce     Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
     */
    function createProxy(bytes memory initializer, uint256 saltNonce) external returns (LaserProxy proxy);

    /**
     * @dev Precomputes the address of a proxy that is created through 'create2'.
     */
    function preComputeAddress(bytes memory initializer, uint256 saltNonce) external view returns (address);

    /**
     * @dev Allows to retrieve the runtime code of a deployed Proxy. This can be used to check that the expected Proxy was deployed.
     */
    function proxyRuntimeCode() external pure returns (bytes memory);

    /**
     *  @dev Allows to retrieve the creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
     */
    function proxyCreationCode() external pure returns (bytes memory);
}