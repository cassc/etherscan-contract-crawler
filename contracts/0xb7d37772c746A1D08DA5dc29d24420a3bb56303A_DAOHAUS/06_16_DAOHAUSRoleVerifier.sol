// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./DAOHAUSAccessControl.sol";

enum DAOHAUSRole {
    PUBLIC, // = 0
    DAOLIST, // = 1
    CREATOR, // = 2
    TEAM // = 3
}

contract DAOHAUSRoleVerifier is DAOHAUSAccessControl {
    // ====== STATE VARIABLES ======

    mapping(DAOHAUSRole => bytes32) internal _merkleRootForRole;

    // ====== MODIFIERS ======

    /**
     * @dev Determines if the caller of this function is a member of `role`
     * using the `merkleProof`.
     *
     * The parameter `merkleProof` will need to be generated from a database of
     * addresses that belong to `role`. It will then be checked against the
     * current merkle root to determine if the address truly exists in the list.
     *
     * Note: The merkle root for the `role` will need to be synced if the
     * aforementioned database of addresses is updated in any way.
     */
    modifier isValidMerkleProofForRole(
        DAOHAUSRole role,
        bytes32[] calldata merkleProof
    ) {
        if (role > DAOHAUSRole.PUBLIC) {
            require(
                _merkleRootForRole[role] != bytes32(0x0),
                "DH_MERKLE_ROOT_NOT_SET"
            );
            require(
                MerkleProof.verify(
                    merkleProof,
                    _merkleRootForRole[role],
                    keccak256(abi.encodePacked(msg.sender))
                ),
                "DH_ROLE_VERIFICATION_FAILED"
            );
        }
        _;
    }

    // ====== EXTERNAL FUNCTIONS ======

    /**
     * @dev Returns the merkle root used in the verification process to check if
     * an address is a member of `role`.
     *
     * You must have at least the OPERATOR role to call this function.
     */
    function merkleRootForRole(DAOHAUSRole role)
        external
        view
        onlyOperator
        returns (bytes32)
    {
        return _merkleRootForRole[role];
    }

    /**
     * @dev Updates the merkle root to keep in sync with the latest version of
     * addresses belonging to `role`.
     *
     * You must have at least the OPERATOR role to call this function.
     */
    function setMerkleRootForRole(DAOHAUSRole role, bytes32 newRoot)
        external
        onlyOperator
    {
        _merkleRootForRole[role] = newRoot;
    }
}