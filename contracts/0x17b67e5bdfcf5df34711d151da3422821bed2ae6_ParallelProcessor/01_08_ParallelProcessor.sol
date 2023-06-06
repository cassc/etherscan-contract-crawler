// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ECDSA} from "openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MerkleProof} from "openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Pausable} from "openzeppelin/contracts/security/Pausable.sol";
import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";

/**
 * Gnosis Module for parallel transaction processing and flexible batch signing.
 */
contract ParallelProcessor is Ownable, Pausable {
    /*===============
        CONSTANTS
    ===============*/

    string public constant VERSION = "0.0.1";
    // keccak256("0.0.1")
    bytes32 internal constant VERSION_HASH = 0xae209a0b48f21c054280f2455d32cf309387644879d9acbd8ffc199163811885;
    // keccak256("Station")
    bytes32 internal constant NAME_HASH = 0x4f784c0e18123f1bcf2019ca9bca613b21be0e82b4989466d1e84401ef31dfbb;

    // keccak256("EIP712Domain(string name)")
    bytes32 internal constant TREE_DOMAIN_TYPEHASH = 0xb2178a58fb1eefb359ecfdd57bb19c0bdd0f4e6eed8547f46600e500ed111af3;
    // keccak256("Tree(bytes32 root)")
    bytes32 internal constant TREE_TYPEHASH = 0x4f5a7143a129271dbc214e4342337d7f887badb3b978736e5a4484df4b6c48b6;
    bytes32 internal constant TREE_DOMAIN_SEPARATOR = keccak256(abi.encode(TREE_DOMAIN_TYPEHASH, NAME_HASH));

    // keccak256("Action(address safe,uint256 nonce,address sender,uint8 operation,address to,uint256 value,bytes data,bytes senderParams)")
    bytes32 internal constant ACTION_TYPEHASH = 0x89b4f446e2d3d67a046a57d61ccb2e43275f7c0e07489b52e3766550d6599ba4;
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 internal constant ACTION_DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    bytes32 internal immutable INITIAL_ACTION_DOMAIN_SEPARATOR;
    uint256 internal immutable INITIAL_CHAIN_ID;

    address internal immutable PARALLEL_PROCESSOR_ADDRESS;

    /*============
        EVENTS
    ============*/

    event Success(address indexed safe, uint256 indexed nonce, bytes32 indexed actionHash, string note);

    /*============
        ERRORS
    ============*/

    error AddressesNotSorted();
    error BelowQuorum();
    error CallFailed();
    error ECDSARecover();
    error InvalidSender();
    error InvalidSignature();
    error NonceUsed();

    /*=============
        STRUCTS
    =============*/

    struct Action {
        address safe;
        uint256 nonce;
        address sender;
        uint8 operation;
        address to;
        uint256 value;
        bytes data;
        bytes senderParams; // used for additional verification from a smart contract `sender`
    }

    struct SignerProof {
        bytes32[] path;
        bytes signature;
    }

    /*=============
        STORAGE
    =============*/

    // (safe => bitmap) for tracking nonces, bitmaps used to enable parallel processing
    mapping(address => mapping(uint256 => uint256)) internal usedNonces;

    /*===================
        INITIALIZATION
    ===================*/

    constructor(address owner) Pausable() {
        _transferOwnership(owner); // Station multi-sig
        INITIAL_ACTION_DOMAIN_SEPARATOR = _getActionDomainSeparator();
        INITIAL_CHAIN_ID = block.chainid;
        PARALLEL_PROCESSOR_ADDRESS = address(this);
    }

    // when deploying a new Safe, setupModules will delegatecall this function, making address(this)
    // the newly deployed Safe and the module address is our immutable PARALLEL_PROCESSOR_ADDRESS
    function enableModuleWithinDeploy() external {
        IGnosisSafe(address(this)).enableModule(PARALLEL_PROCESSOR_ADDRESS);
    }

    /*===============
        EXECUTION
    ===============*/

    // execute a call through a Safe
    function execute(Action calldata action, SignerProof[] calldata proofs, string calldata note)
        external
        whenNotPaused
        returns (bool success)
    {
        if (action.sender != address(0) && action.sender != msg.sender) {
            revert InvalidSender();
        }

        // use nonce immediately to protect from reentrancy and replay attacks
        _useNonce(action.safe, action.nonce);

        bytes32 actionHash = getActionHash(action);

        // verify signatures are valid
        _validateProofs(action.safe, actionHash, proofs);

        // execute transaction
        success =
            IGnosisSafe(action.safe).execTransactionFromModule(action.to, action.value, action.data, action.operation);

        // prevent DOS attacks via insufficient gas by enforcing call success
        if (!success) revert CallFailed();

        emit Success(action.safe, action.nonce, actionHash, note);

        // returns success
    }

    /*==================
        VERIFICATION
    ==================*/

    function isNonceUsed(address safe, uint256 nonce) external view returns (bool) {
        uint256 word = nonce >> 8;
        uint256 mask = 1 << (nonce & 0xff);
        return usedNonces[safe][word] & mask != 0;
    }

    function useNonce(address safe, uint256 nonce) public returns (bool) {
        // only other enabled modules are allowed to use nonces
        if (!IGnosisSafe(safe).isModuleEnabled(msg.sender)) revert InvalidSender();
        _useNonce(safe, nonce);
        return true;
    }

    function _useNonce(address safe, uint256 nonce) internal {
        uint256 word = nonce >> 8;
        uint256 mask = 1 << (nonce & 0xff);
        uint256 row = usedNonces[safe][word];
        if (row & mask != 0) revert NonceUsed();
        usedNonces[safe][word] = row | mask;
    }

    function _validateProofs(address safe, bytes32 actionHash, SignerProof[] memory proofs) internal view {
        IGnosisSafe Safe = IGnosisSafe(safe);
        if (proofs.length < Safe.getThreshold()) revert BelowQuorum();
        address previous;
        address current;
        ECDSA.RecoverError error;
        for (uint256 i; i < proofs.length; i++) {
            // assemble root of signed merkle tree
            bytes32 root = MerkleProof.processProof(proofs[i].path, actionHash);
            // hash root within EIP712 object
            bytes32 treeHash = getTreeHash(root);
            // recover signer from hash and signature
            (current, error) = ECDSA.tryRecover(treeHash, proofs[i].signature);
            // require no errors recovering address from signature
            if (error != ECDSA.RecoverError.NoError) revert ECDSARecover();
            // require signer is owner on Safe
            if (!Safe.isOwner(current)) revert InvalidSignature();
            // enforce address ordering to guarantee uniqueness of signers
            if (current <= previous) revert AddressesNotSorted();
            previous = current;
        }
    }

    // public for testing convenience
    function getTreeHash(bytes32 root) public pure returns (bytes32 treeHash) {
        bytes32 valuesHash = keccak256(abi.encode(TREE_TYPEHASH, root));

        treeHash = ECDSA.toTypedDataHash(TREE_DOMAIN_SEPARATOR, valuesHash);
    }

    // public for testing convenience
    function getActionHash(Action calldata action) public view returns (bytes32 actionHash) {
        bytes32 valuesHash = keccak256(
            abi.encode(
                ACTION_TYPEHASH,
                action.safe,
                action.nonce,
                action.sender,
                action.operation,
                action.to,
                action.value,
                // per EIP712 spec, need to hash variable length data to 32-bytes value first
                keccak256(action.data),
                keccak256(action.senderParams)
            )
        );

        actionHash = ECDSA.toTypedDataHash(
            block.chainid == INITIAL_CHAIN_ID ? INITIAL_ACTION_DOMAIN_SEPARATOR : _getActionDomainSeparator(),
            valuesHash
        );
    }

    function _getActionDomainSeparator() internal view returns (bytes32) {
        return keccak256(abi.encode(ACTION_DOMAIN_TYPEHASH, NAME_HASH, VERSION_HASH, block.chainid, address(this)));
    }

    /*===============
        EMERGENCY
    ===============*/

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _pause();
    }
}

interface IGnosisSafe {
    function getThreshold() external view returns (uint256);
    function isOwner(address owner) external view returns (bool);
    function execTransactionFromModule(address to, uint256 value, bytes memory data, uint8 operation)
        external
        returns (bool);
    function enableModule(address module) external;
    function isModuleEnabled(address module) external view returns (bool);
}