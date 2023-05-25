// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IDoubleDrop {
    /**
      * Elementals provenance contract cannot be null
      */
    error ProvenanceContractCannotBeNull();

    /**
      * Elementals provenance not set
      */
    error ElementalsProvenanceNotSet();

    /**
      * Elementals provenance already set
      */
    error ElementalsProvenanceAlreadySet();

    /**
     * Redemption contracts already set
     */
    error ContractsAlreadyInitialized();

    /**
     * Redemption contracts cannot be NULL
     */
    error ContractsCannotBeNull();

    /**
     * Redemption contracts are not yet set
     */
    error ContractsNotInitialized();

    /**
     * Redemption is not active
     */
    error RedemptionNotActive();

    /**
     * Invalid signature provided
     */
    error InvalidSignature();

    /**
     * Hashmask token already used for redemption
     */
    error TokenAlreadyRedeemed();

    /**
     * Address is not the token owner
     */
    error NotTokenOwner();
}