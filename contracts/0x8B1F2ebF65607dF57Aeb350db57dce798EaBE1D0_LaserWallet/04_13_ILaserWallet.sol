// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/**
 * @title  ILaserWallet
 *
 * @author Rodrigo Herrera I.
 *
 * @notice Laser is a modular smart contract wallet made for the Ethereum Virtual Machine.
 *         It has modularity (programmability) and security at its core.
 *
 * @dev    This interface has all events, errors, and external function for LaserWallet.
 */
interface ILaserWallet {
    event Setup(address owner, address laserModule);
    event ExecSuccess(address to, uint256 value, uint256 nonce);
    event ExecFailure(address to, uint256 value, uint256 nonce);

    // init() custom errors.
    error LW__init__notOwner();
    error LW__init__refundFailure();

    // exec() custom errors.
    error LW__exec__invalidNonce();
    error LW__exec__walletLocked();
    error LW__exec__notOwner();
    error LW__exec__refundFailure();

    // execFromModule() custom errors.
    error LW__execFromModule__unauthorizedModule();
    error LW__execFromModule__mainCallFailed();
    error LW__execFromModule__refundFailure();

    // simulateTransaction() custom errors.
    error LW__SIMULATION__invalidNonce();
    error LW__SIMULATION__walletLocked();
    error LW__SIMULATION__notOwner();
    error LW__SIMULATION__refundFailure();

    // isValidSignature() Laser custom error.
    error LaserWallet__invalidSignature();

    struct Transaction {
        address to;
        uint256 value;
        bytes callData;
        uint256 nonce;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        uint256 gasLimit;
        address relayer;
        bytes signatures;
    }

    /**
     * @notice Setup function, sets initial storage of the wallet.
     *         It can't be called after initialization.
     *
     * @param _owner                        The owner of the wallet.
     * @param maxFeePerGas                  Maximum WEI the owner is willing to pay per unit of gas.
     * @param maxPriorityFeePerGas          Miner's tip.
     * @param gasLimit                      Maximum amount of gas the owner is willing to use for this transaction.
     * @param relayer                       Address to refund for the inclusion of this transaction.
     * @param smartSocialRecoveryModule     Address of the initial module to setup -> Smart Social Recovery.
     * @param _laserMasterGuard             Address of the parent guard module 'LaserMasterGuard'.
     * @param laserVault                    Address of the guard sub-module 'LaserVault'.
     * @param _laserRegistry                Address of the Laser registry: module that keeps track of authorized modules.
     * @param smartSocialRecoveryInitData   Initialization data for the provided module.
     * @param ownerSignature                Signature of the owner that validates approval for initialization.
     */
    function init(
        address _owner,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        address smartSocialRecoveryModule,
        address _laserMasterGuard,
        address laserVault,
        address _laserRegistry,
        bytes calldata smartSocialRecoveryInitData,
        bytes memory ownerSignature
    ) external;

    /**
     * @notice Executes a generic transaction.
     *         If 'gasLimit' does not match the actual gas limit of the transaction, the relayer can incur losses.
     *         It is the relayer's responsability to make sure that they are the same,
     *         the user does not get affected if a mistake is made.
     *
     * @param to                    Destination address.
     * @param value                 Amount in WEI to transfer.
     * @param callData              Data payload for the transaction.
     * @param _nonce                Anti-replay number.
     * @param maxFeePerGas          Maximum WEI the owner is willing to pay per unit of gas.
     * @param maxPriorityFeePerGas  Miner's tip.
     * @param gasLimit              Maximum amount of gas the owner is willing to use for this transaction.
     * @param relayer               Address to refund for the inclusion of this transaction.
     * @param signatures            The signature(s) of the hash for this transaction.
     */
    function exec(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        bytes calldata signatures
    ) external returns (bool success);

    /**
     * @notice Executes a transaction from an authorized module.
     *         If 'gasLimit' does not match the actual gas limit of the transaction, the relayer can incur losses.
     *         It is the relayer's responsability to make sure that they are the same,
     *         the user does not get affected if a mistake is made.
     *
     * @param to                    Destination address.
     * @param value                 Amount in WEI to transfer.
     * @param callData              Data payload for the transaction.
     * @param maxFeePerGas          Maximum WEI the owner is willing to pay per unit of gas.
     * @param maxPriorityFeePerGas  Miner's tip.
     * @param gasLimit              Maximum amount of gas the owner is willing to use for this transaction.
     * @param relayer               Address to refund for the inclusion of this transaction.
     */
    function execFromModule(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer
    ) external;

    /**
     * @notice Simulates a transaction.
     *         It needs to be called off-chain from address(0).
     *
     * @param to                    Destination address.
     * @param value                 Amount in WEI to transfer.
     * @param callData              Data payload for the transaction.
     * @param _nonce                Anti-replay number.
     * @param maxFeePerGas          Maximum WEI the owner is willing to pay per unit of gas.
     * @param maxPriorityFeePerGas  Miner's tip.
     * @param gasLimit              Maximum amount of gas the owner is willing to use for this transaction.
     * @param relayer               Address to refund for the inclusion of this transaction.
     * @param signatures            The signature(s) of the hash of this transaction.
     *
     * @return gasUsed The gas used for this transaction.
     */
    function simulateTransaction(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        bytes calldata signatures
    ) external returns (uint256 gasUsed);

    /**
     * @notice Locks the wallet. Once locked, only the SSR module can unlock it or recover it.
     *
     * @dev Can only be called by address(this).
     */
    function lock() external;

    /**
     * @notice Unlocks the wallet. Can only be unlocked or recovered from the SSR module.
     *
     * @dev Can only be called by address(this).
     */
    function unlock() external;

    /**
     * @notice Should return whether the signature provided is valid for the provided hash.
     *
     * @param hash      Hash of the data to be signed.
     * @param signature Signature byte array associated with hash.
     *
     * MUST return the bytes4 magic value 0x1626ba7e when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     *
     * @return Magic value if signature matches the owner's address and the wallet is not locked.
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4);

    /**
     * @notice Returns the hash to be signed to execute a transaction.
     */
    function operationHash(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit
    ) external view returns (bytes32);

    /**
     * @return chainId The chain id of this.
     */
    function getChainId() external view returns (uint256 chainId);

    /**
     * @notice Domain separator for this wallet.
     */
    function domainSeparator() external view returns (bytes32);
}