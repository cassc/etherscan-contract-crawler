// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/**
 * @title Different role definitions used by the ACL contract.
 */
library Roles {
    /**
     * @dev This maps directly to the OpenZeppelins AccessControl DEFAULT_ADMIN_ROLE
     */
    bytes32 public constant ADMIN = 0x00;
    bytes32 public constant OPERATOR = keccak256("OPERATOR_ROLE");
    bytes32 public constant MINTER = keccak256("MINTER_ROLE");
    bytes32 public constant FREE_CLAIMER = keccak256("FREE_CLAIMER_ROLE");
    /**
     * @dev Some platforms (OpenSea, BEP20, etc) require contracts to have
     *      owner() or getOwner() function. This role is dedicated only to
     *      make these platforms happy. This role does not have any functional
     *      limitations/priveleges.
     */
    bytes32 public constant OWNER = keccak256("OWNER_ROLE");
}