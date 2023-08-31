// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

uint256 constant VALUES_ARR_SIZE = 64;

/**
 * @title IOffChainCircuitValidator
 * @notice Interface to OffChain validators that are required to validate credentialAtomicQuerySigV2 and credentialAtomicQueryMtpV2 circom schemes
 */
interface IOffChainCircuitValidator {
    /**
     * @notice Structure that stores the parameters needed for additional proof validation
     * @param issuerId the ID of the issuer
     * @param issuerClaimState the issuer state, in which there is a confirmation that the claim is included in the issuer's claim tree
     * @param issuerClaimNonRevState the issuer non revocation state
     * @param isRevocationChecked the flag that indicates whether the revocation of the claim is being checked
     */
    struct ValidationParams {
        uint256 issuerId;
        uint256 issuerClaimState;
        uint256 issuerClaimNonRevState;
        bool isRevocationChecked;
    }

    /**
     * @notice The structure in which the query schema is stored
     * @param schema the identifier of the claim schema to be checked
     * @param claimPathKey path to the field in the mercalized claim tree
     * @param operator the operator to be used in the check (eq, lt, gt, in, nin, etc.)
     * @param value the array of values to be checked inside ZK proofs
     * @param queryHash the circuit query hash
     * @param circuitId the circuit query ID
     */
    struct CircuitQuery {
        uint256 schema;
        uint256 claimPathKey;
        uint256 operator;
        uint256[] value;
        uint256 queryHash;
        string circuitId;
    }

    /**
     * @notice Function for ZK proof verification with additional data validation
     * @param inputs_ the array with the public ZK proof inputs
     * @param a_ the A point of the ZK proof
     * @param b_ the B points of the ZK proof
     * @param c_ the C point of the ZK proof
     * @param queryHash_ the hash of the query to be checked in the ZK proof
     */
    function verify(
        uint256[] memory inputs_,
        uint256[2] memory a_,
        uint256[2][2] memory b_,
        uint256[2] memory c_,
        uint256 queryHash_
    ) external view returns (bool r_);

    /**
     * @notice Function for getting the circuit identifier
     * @return Circuit identifier string
     */
    function getCircuitId() external view returns (string memory);
}