// SPDX-License-Identifier: MIT
// Copyright 2023 Proof Holdings Inc.
pragma solidity >=0.8.17;

import {IEntropyOracle, IEntropyOracleEvents} from "./IEntropyOracle.sol";
import {AccessControlEnumerable} from "ethier/utils/AccessControlEnumerable.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";

/**
 * @notice Returns the digest that the oracle is expected to sign for a given block's entropy. The keccak256 of this
 * (deterministic) signature is the block entropy. The security level of the entropy is therefore inherited from the
 * security level of the signature.
 */
function blockDigest(uint256 blockNumber) view returns (bytes32) {
    return ECDSA.toEthSignedMessageHash(abi.encode(blockNumber, block.chainid));
}

/**
 * @notice Allows for specific addresses to request entropy from an external source in a verifiable manner.
 * @dev Entropy requests emit events that can be used for automatic fulfilment.
 * @dev Limitation: the oracle is a centralised entity that can look ahead to future entropy should it choose to; it
 * MUST therefore be trusted by all parties that wish to protect against entropy snooping. In practice, this usually
 * means a contract owner protecting against malicious users, but not vice versa.
 */
contract EntropyOracle is IEntropyOracle, AccessControlEnumerable {
    /**
     * @notice Entropy MUST NOT be *provided* for the current nor future blocks.
     */
    error NonHistoricalBlock(uint256 blockNumber);

    /**
     * @notice The signature for the provided entropy was not provided by the oracle.
     */
    error InvalidEntropySignature();

    /**
     * @notice Entropy has already been provided for the specified block.
     */
    error EntropyAlreadyProvided(uint256 blockNumber);

    /**
     * @notice Defines the addresses allowed to request entropy.
     */
    bytes32 public constant ENTROPY_REQUESTER_ROLE = keccak256("ENTROPY_REQUESTER_ROLE");

    /**
     * @notice The address of the oracle providing entropy.
     */
    address public signer;

    /**
     * @notice Provided entropy.
     * @dev Value of 0 indicates that entropy has been neither requested nor provided; value of 1 indicates that it has
     * been requested but not yet provided.
     */
    mapping(uint256 => bytes32) private _blockEntropy;

    constructor(address admin, address steerer) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(DEFAULT_STEERING_ROLE, steerer);
        _setRoleAdmin(ENTROPY_REQUESTER_ROLE, DEFAULT_STEERING_ROLE);
    }

    /**
     * @inheritdoc IEntropyOracle
     */
    function requestEntropy() public {
        requestEntropy(block.number);
    }

    /**
     * @inheritdoc IEntropyOracle
     */
    function requestEntropy(uint256 blockNumber) public onlyRole(ENTROPY_REQUESTER_ROLE) {
        if (_blockEntropy[blockNumber] == 0) {
            emit EntropyRequested(blockNumber);
            _blockEntropy[blockNumber] = bytes32(uint256(1));
        }
    }

    /**
     * @notice Input argument to provideEntropy() for specifying multiple blocks in a single call.
     */
    struct EntropyFulfilment {
        uint256 blockNumber;
        bytes signature;
    }

    /**
     * @notice Fulfil a request for entropy. The block MUST be historical.
     * @dev Entropy MAY be provided for a block even if it wasn't explicitly requested.
     */
    function provideEntropy(EntropyFulfilment calldata entropy) external virtual {
        _provideEntropy(entropy);
    }

    function _provideEntropy(EntropyFulfilment calldata entropy) internal returns (bytes32) {
        uint256 blockNumber = entropy.blockNumber;
        if (blockNumber >= block.number) {
            revert NonHistoricalBlock(blockNumber);
        }
        if (ECDSA.recover(blockDigest(blockNumber), entropy.signature) != signer) {
            revert InvalidEntropySignature();
        }
        if (blockEntropy(blockNumber) != 0) {
            revert EntropyAlreadyProvided(blockNumber);
        }

        bytes32 hashed = keccak256(entropy.signature);
        _blockEntropy[blockNumber] = hashed;
        emit EntropyProvided(blockNumber, hashed);
        return hashed;
    }

    /**
     * @notice Fulfil multiple requests for entropy.
     * @dev Equivalent to multiple calls to the single-block equivalent of provideEntropy().
     */
    function provideEntropy(EntropyFulfilment[] calldata entropy) external virtual {
        for (uint256 i = 0; i < entropy.length; ++i) {
            _provideEntropy(entropy[i]);
        }
    }

    /**
     * @inheritdoc IEntropyOracle
     */
    function blockEntropy(uint256 blockNumber) public view virtual returns (bytes32) {
        bytes32 entropy = _blockEntropy[blockNumber];
        if (uint256(entropy) > 1) {
            return entropy;
        }
        return 0;
    }

    /**
     * @notice Updates the oracle's signing address.
     */
    function setSigner(address signer_) external onlyRole(DEFAULT_STEERING_ROLE) {
        signer = signer_;
    }
}