// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/**
 * @title  ILaserMasterGuard
 *
 * @author Rodrigo Herrera I.
 *
 * @notice Parent guard module that calls child Laser guards.
 *
 * @dev    This interface has all events, errors, and external function for LaserMasterGuard.
 */
interface ILaserMasterGuard {
    // addGuardModule() custom errors.
    error LaserMasterGuard__addGuardModule__unauthorizedModule();
    error LaserMasterGuard__addGuardModule__overflow();

    // removeGuardModule custom errors.
    error LaserMasterGuard__removeGuardModule__incorrectModule();
    error LaserMasterGuard__removeGuardModule__incorrectPrevModule();

    /**
     * @notice Adds a new guard module.
     *         wallet is 'msg.sender'.
     *
     * @param module The address of the new module. It needs to be authorized in LaserRegistry.
     */
    function addGuardModule(address module) external;

    /**
     * @notice Removes a guard module.
     * wallet is 'msg.sender'.
     *
     * @param prevModule    The address of the previous module on the linked list.
     * @param module        The address of the module to remove.
     */
    function removeGuardModule(
        address prevModule,
        address module,
        bytes calldata guardianSignature
    ) external;

    /**
     * @notice Verifies a Laser transaction.
     *         It calls all guard sub-modules with the 'verifyTransaction api'.
     *         Each sub-module implements its own logic. But the main purpose is to
     *         provide extra transaction security.
     *
     * @param wallet                The address of the wallet: should be 'msg.sender'.
     * @param to                    Destination address.
     * @param value                 Amount in WEI to transfer.
     * @param callData              Data payload for the transaction.
     * @param nonce                 Anti-replay number.
     * @param maxFeePerGas          Maximum WEI the owner is willing to pay per unit of gas.
     * @param maxPriorityFeePerGas  Miner's tip.
     * @param gasLimit              Maximum amount of gas the owner is willing to use for this transaction.
     * @param signatures            The signature(s) of the hash of this transaction.
     */
    function verifyTransaction(
        address wallet,
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        bytes memory signatures
    ) external;

    /**
     * @param wallet The requested address.
     *
     * @return The guard modules that belong to the requested address.
     */
    function getGuardModules(address wallet) external view returns (address[] memory);
}