// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

import "./handlers/Handler.sol";
import "./interfaces/ILaserWallet.sol";
import "./state/LaserState.sol";

/**
 * @title  LaserWallet
 *
 * @author Rodrigo Herrera I.
 *
 * @notice Laser is a secure smart contract wallet (vault) made for the Ethereum Virtual Machine.
 */
contract LaserWallet is ILaserWallet, LaserState, Handler {
    /*//////////////////////////////////////////////////////////////
                             LASER METADATA
    //////////////////////////////////////////////////////////////*/

    string public constant VERSION = "1.0.0";

    string public constant NAME = "Laser Wallet";

    /*//////////////////////////////////////////////////////////////
                            SIGNATURE TYPES
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH =
        keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");

    bytes32 private constant LASER_TYPE_STRUCTURE =
        keccak256("LaserOperation(address to,uint256 value,bytes callData,uint256 nonce)");

    /**
     * @dev Sets the owner of the implementation address (singleton) to 'this'.
     *      This will make the base contract unusable, even though it does not have 'delegatecall'.
     */
    constructor() {
        owner = address(this);
    }

    receive() external payable {}

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
    ) external {
        // activateWallet verifies that the current owner is address 0, reverts otherwise.
        // This is more than enough to avoid being called after initialization.
        activateWallet(_owner, _guardians, _recoveryOwners);

        // This is primarily to verify that the owner address is correct.
        // It also provides some extra security guarantes (the owner really approved the guardians and recovery owners).
        bytes32 signedHash = keccak256(abi.encodePacked(_guardians, _recoveryOwners, block.chainid));

        address signer = Utils.returnSigner(signedHash, ownerSignature, 0);

        if (signer != _owner) revert LW__init__notOwner();
    }

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
    ) public returns (bool success) {
        // We immediately increase the nonce to avoid replay attacks.
        unchecked {
            if (nonce++ != _nonce) revert LW__exec__invalidNonce();
        }

        // If the wallet is locked, further transactions cannot be executed from 'exec'.
        if (walletConfig.isLocked) revert LW__exec__walletLocked();

        // We get the hash for this transaction.
        bytes32 signedHash = keccak256(encodeOperation(to, value, callData, _nonce));

        if (signatures.length < 130) revert LW__exec__invalidSignatureLength();

        address signer1 = Utils.returnSigner(signedHash, signatures, 0);
        address signer2 = Utils.returnSigner(signedHash, signatures, 1);

        if (signer1 != owner || (recoveryOwners[signer2] == address(0) && guardians[signer2] == address(0))) {
            revert LW__exec__invalidSignature();
        }

        success = Utils.call(to, value, callData, gasleft());
        if (!success) revert LW__exec__callFailed();

        emit ExecSuccess(to, value, nonce, bytes4(callData));
    }

    /**
     * @notice Executes a batch of transactions.
     *
     * @param transactions An array of Laser transactions.
     */
    function multiCall(Transaction[] calldata transactions) external {
        uint256 transactionsLength = transactions.length;

        // @todo custom errors and optimization.
        // This is a mockup, not final.
        for (uint256 i = 0; i < transactionsLength; ) {
            Transaction calldata transaction = transactions[i];

            exec(transaction.to, transaction.value, transaction.callData, transaction.nonce, transaction.signatures);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Triggers the recovery mechanism.
     *
     * @param callData   Data payload, can only be either lock(), unlock() or recover(address).
     * @param signatures Signatures of the hash of the transaction.
     */
    function recovery(
        uint256 _nonce,
        bytes calldata callData,
        bytes calldata signatures
    ) external {
        // We immediately increase the nonce to avoid replay attacks.
        unchecked {
            if (nonce++ != _nonce) revert LW__recovery__invalidNonce();
        }

        bytes4 functionSelector = bytes4(callData);

        // All calls require at least 2 signatures.
        if (signatures.length < 130) revert LW__recovery__invalidSignatureLength();

        bytes32 signedHash = keccak256(abi.encodePacked(_nonce, keccak256(callData), address(this), block.chainid));

        address signer1 = Utils.returnSigner(signedHash, signatures, 0);
        address signer2 = Utils.returnSigner(signedHash, signatures, 1);

        if (signer1 == signer2) revert LW__recovery__duplicateSigner();

        if (functionSelector == 0xf83d08ba) {
            // bytes4(keccak256("lock()"))

            // Only a recovery owner + recovery owner || recovery owner + guardian
            // can lock the wallet.
            if (
                recoveryOwners[signer1] == address(0) ||
                (recoveryOwners[signer2] == address(0) && guardians[signer2] == address(0))
            ) revert LW__recoveryLock__invalidSignature();
        } else if (functionSelector == 0xa69df4b5) {
            // bytes4(keccak256("unlock()"))

            // Only the owner + recovery owner || owner + guardian can unlock the wallet.
            if (signer1 != owner || (recoveryOwners[signer2] == address(0) && guardians[signer2] == address(0))) {
                revert LW__recoveryUnlock__invalidSignature();
            }
        } else if (functionSelector == 0x0cd865ec) {
            // bytes4(keccak256("recover(address)"))

            // Only the recovery owner + recovery owner || recovery owner + guardian can recover the wallet.
            if (
                recoveryOwners[signer1] == address(0) ||
                (recoveryOwners[signer2] == address(0) && guardians[signer2] == address(0))
            ) revert LW__recoveryRecover__invalidSignature();
        } else {
            // Else, the operation is not allowed.
            revert LW__recovery__invalidOperation();
        }

        bool success = Utils.call(address(this), 0, callData, gasleft());
        if (!success) revert LW__recovery__callFailed();
    }

    /**
     * @notice Returns the hash to be signed to execute a transaction.
     */
    function operationHash(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce
    ) external view returns (bytes32) {
        return keccak256(encodeOperation(to, value, callData, _nonce));
    }

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
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4) {
        address signer1 = Utils.returnSigner(hash, signature, 0);
        address signer2 = Utils.returnSigner(hash, signature, 1);

        if (signer1 != owner || (recoveryOwners[signer2] == address(0) && guardians[signer2] == address(0))) {
            revert LaserWallet__invalidSignature();
        }

        // bytes4(keccak256("isValidSignature(bytes32,bytes)")
        return 0x1626ba7e;
    }

    /**
     * @return chainId The chain id of this.
     */
    function getChainId() public view returns (uint256 chainId) {
        return block.chainid;
    }

    /**
     * @notice Domain separator for this wallet.
     */
    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), address(this)));
    }

    /**
     * @notice Encodes the transaction data.
     */
    function encodeOperation(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce
    ) internal view returns (bytes memory) {
        bytes32 opHash = keccak256(abi.encode(LASER_TYPE_STRUCTURE, to, value, keccak256(callData), _nonce));

        return abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), opHash);
    }
}