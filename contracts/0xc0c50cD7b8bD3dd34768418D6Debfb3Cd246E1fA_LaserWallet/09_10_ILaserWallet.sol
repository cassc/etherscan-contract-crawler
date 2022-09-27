// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

struct Transaction {
    address to;
    uint256 value;
    bytes callData;
    uint256 nonce;
    bytes signatures;
}

/**
 * @title  ILaserWallet
 *
 * @author Rodrigo Herrera I.
 *
 * @notice Laser is a secure smart contract wallet (vault) made for the Ethereum Virtual Machine.
 *
 * @dev    This interface has all events, errors, and external function for LaserWallet.
 */
interface ILaserWallet {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ExecSuccess(address to, uint256 value, uint256 nonce, bytes4 funcSig);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error LW__init__notOwner();

    error LW__exec__invalidNonce();

    error LW__exec__walletLocked();

    error LW__exec__invalidSignatureLength();

    error LW__exec__invalidSignature();

    error LW__exec__callFailed();

    error LW__recovery__invalidNonce();

    error LW__recovery__invalidSignatureLength();

    error LW__recovery__duplicateSigner();

    error LW__recoveryLock__invalidSignature();

    error LW__recoveryUnlock__time();

    error LW__recoveryUnlock__invalidSignature();

    error LW__recoveryRecover__walletLocked();

    error LW__recoveryRecover__invalidSignature();

    error LW__recovery__invalidOperation();

    error LW__recovery__callFailed();

    error LaserWallet__invalidSignature();

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Setup function, sets initial storage of the wallet.
     *         It can't be called after initialization.
     *
     * @param _owner           The owner of the wallet.
     * @param _guardians       Array of guardians.
     * @param _recoveryOwners  Array of recovery owners.
     * @param ownerSignature   Signature of the owner that validates the correctness of the address.
     */
    function init(
        address _owner,
        address[] calldata _guardians,
        address[] calldata _recoveryOwners,
        bytes calldata ownerSignature
    ) external;

    /**
     * @notice Executes a generic transaction.
     *         The transaction is required to be signed by the owner + recovery owner or owner + guardian
     *         while the wallet is not locked.
     *
     * @param to         Destination address.
     * @param value      Amount in WEI to transfer.
     * @param callData   Data payload to send.
     * @param _nonce     Anti-replay number.
     * @param signatures Signatures of the hash of the transaction.
     */
    function exec(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        bytes calldata signatures
    ) external returns (bool success);

    /**
     * @notice Executes a batch of transactions.
     *
     * @param transactions An array of Laser transactions.
     */
    function multiCall(Transaction[] calldata transactions) external;

    /**
     * @notice Triggers the recovery mechanism.
     *
     * @param callData   Data payload, can only be either lock(), unlock() or recover().
     * @param signatures Signatures of the hash of the transaction.
     */
    function recovery(
        uint256 _nonce,
        bytes calldata callData,
        bytes calldata signatures
    ) external;

    /**
     * @notice Returns the hash to be signed to execute a transaction.
     */
    function operationHash(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce
    ) external view returns (bytes32);

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
     * @return Magic value.
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4);

    /**
     * @return chainId The chain id of this.
     */
    function getChainId() external view returns (uint256 chainId);

    /**
     * @notice Domain separator for this wallet.
     */
    function domainSeparator() external view returns (bytes32);
}