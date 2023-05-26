// SPDX-License-Identifier: UNLICENSED
// SEE LICENSE IN https://files.altlayer.io/Alt-Research-License-1.md
// Copyright Alt Research Ltd. 2023. All rights reserved.
//
// You acknowledge and agree that Alt Research Ltd. ("Alt Research") (or Alt
// Research's licensors) own all legal rights, titles and interests in and to the
// work, software, application, source code, documentation and any other documents

pragma solidity ^0.8.18;

import {IFinalize} from "./interfaces/IFinalize.sol";
import {IFinalizer} from "./interfaces/IFinalizer.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

contract Finalizer is IFinalizer, AccessControlUpgradeable {
    error RootNotFound();
    error AlreadyFinalized();
    error FailedToVerify();
    error NotMerkleRootAdmin();

    bytes32 public constant MERKLE_ROOT_ADMIN_ROLE =
        keccak256("MERKLE_ROOT_ADMIN_ROLE");

    mapping(uint256 => mapping(bytes32 => bool)) public finalized;
    mapping(uint256 => bytes32) public merkleRoots;

    /// @dev This empty reserved space is put in place to allow future versions to add new
    /// variables without shifting down storage in the inheritance chain.
    /// See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    // slither-disable-next-line unused-state
    uint256[47] private __gap;

    modifier onlyMerkleRootAdmin() {
        if (!hasRole(MERKLE_ROOT_ADMIN_ROLE, _msgSender())) {
            revert NotMerkleRootAdmin();
        }
        _;
    }

    function initialize(
        address initialDefaultAdmin,
        address initialMerkleRootAdmin
    ) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, initialDefaultAdmin);
        _grantRole(MERKLE_ROOT_ADMIN_ROLE, initialMerkleRootAdmin);
    }

    /// @inheritdoc IFinalizer
    function setMerkleRoot(
        address target,
        uint64 nonce,
        bytes32 root
    ) external onlyMerkleRootAdmin {
        emit SetMerkleRoot(target, nonce, root, _msgSender());
        merkleRoots[_targetAndNonce(target, nonce)] = root;
    }

    /// @inheritdoc IFinalizer
    function executeFinalization(
        address target,
        uint64 nonce,
        bytes32[] calldata proof,
        bytes calldata data
    ) external virtual {
        _executeFinalization(target, nonce, proof, data);
        IFinalize(target).finalize(data);
    }

    function _executeFinalization(
        address target,
        uint64 nonce,
        bytes32[] calldata proof,
        bytes calldata data
    ) internal {
        uint256 key = _targetAndNonce(target, nonce);
        bytes32 leaf = keccak256(data);
        bytes32 root = merkleRoots[key];

        // Checks
        if (root == "") {
            revert RootNotFound();
        }

        if (finalized[key][leaf]) {
            revert AlreadyFinalized();
        }

        if (!MerkleProofUpgradeable.verifyCalldata(proof, root, leaf)) {
            revert FailedToVerify();
        }

        // Effects
        // This prevents double execution.
        emit Finalized(target, nonce, root, leaf, _msgSender());
        finalized[key][leaf] = true;
    }

    function _targetAndNonce(
        address target,
        uint64 nonce
    ) internal pure returns (uint256) {
        return (uint256(uint160(target)) << 64) | uint256(nonce);
    }
}