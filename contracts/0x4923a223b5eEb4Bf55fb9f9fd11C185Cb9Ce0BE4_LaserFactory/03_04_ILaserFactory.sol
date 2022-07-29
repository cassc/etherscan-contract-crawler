// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

import "../proxies/LaserProxy.sol";

/**
 * @title ILaserFactory.
 * @notice Has all the external functions, events and errors for ProxyFactory.sol.
 */

interface ILaserFactory {
    event ProxyCreation(address proxy);

    ///@dev constructor() custom error.
    error LaserFactory__constructor__invalidSingleton();

    ///@dev createProxyWithCreate2() custom error.
    error LaserFactory__create2Failed();

    /**
     * @dev Creates a new proxy with create 2, initializes the wallet and refunds the relayer.
     * @param maxFeePerGas Maximum amount that the user is willing to pay for a unit of gas.
     * @param maxPriorityFeePerGas Miner's tip.
     * @param gasLimit The transaction's gas limit. It needs to be the same as the actual transaction gas limit.
     * @param relayer Address that forwards the transaction so it abstracts away the gas costs.
     * @param ownerSignature The signatures of the transaction.
     * @notice If 'gasLimit' does not match the actual gas limit of the transaction, the relayer can incur losses.
     * It is the relayer's responsability to make sure that they are the same, the user does not get affected if a mistake is made.
     * We prefer to prioritize the user's safety (not overpay) over the relayer.
     */
    function deployProxyAndRefund(
        address owner,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        address laserModule,
        bytes calldata laserModuleData,
        uint256 saltNumber,
        bytes calldata ownerSignature
    ) external returns (LaserProxy proxy);

    /**
     * @dev Precomputes the address of a proxy that is created through 'create2'.
     */
    function preComputeAddress(
        address owner,
        address laserModule,
        bytes calldata laserModuleData,
        uint256 saltNumber
    ) external view returns (address);

    /**
     * @dev Allows to retrieve the runtime code of a deployed Proxy. This can be used to check that the expected Proxy was deployed.
     */
    function proxyRuntimeCode() external pure returns (bytes memory);

    /**
     *  @dev Allows to retrieve the creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
     */
    function proxyCreationCode() external pure returns (bytes memory);
}