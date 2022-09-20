/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./interfaces/IBlockHistory.sol";
import "./interfaces/IFeeDelegate.sol";
import "./lib/Facts.sol";

struct PendingProver {
    uint64 timestamp;
    uint64 version;
}

struct ProverInfo {
    uint64 version;
    FeeInfo feeInfo;
    bool revoked;
}

// It would be nice if these could be stored in ReliquaryWithFee, but we want
// to store fee information in ProverInfo for gas optimization.
enum FeeFlags {
    FeeNone,
    FeeNative,
    FeeCredits,
    FeeExternalDelegate,
    FeeExternalToken
}

struct FeeInfo {
    uint8 flags;
    uint16 feeCredits;
    // feeWei = feeWeiMantissa * pow(10, feeWeiExponent)
    uint8 feeWeiMantissa;
    uint8 feeWeiExponent;
    uint32 feeExternalId;
}

/**
 * @title Holder of Relics and Artifacts
 * @author Theori, Inc.
 * @notice The Reliquary is the heart of Relic. All issuers of Relics and Artifacts
 *         must be added to the Reliquary. Queries about Relics and Artifacts should
 *         be made to the Reliquary.
 */
contract Reliquary is AccessControl {
    /// Minimum delay before a new prover can be active
    uint64 public constant DELAY = 2 days;

    bytes32 public constant ADD_PROVER_ROLE = keccak256("ADD_PROVER_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    /// Once initialized, new provers can only be added with a delay
    bool public initialized;
    /// Append-only map of added prover addresses to information on them
    mapping(address => ProverInfo) public provers;
    /**
     *  Reverse mapping of version information to the unique prover able
     *  to issue statements with that version
     */
    mapping(uint64 => address) public versions;
    /// List of provers that may be added to the Reliquary, for public scrutiny
    mapping(address => PendingProver) public pendingProvers;

    mapping(address => mapping(FactSignature => bytes)) internal provenFacts;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Issued when a new prover is accepted into the Reliquary
     * @param prover the address of the prover contract
     * @param version the identifier that will always be associated with the prover
     */
    event NewProver(address prover, uint64 version);

    /**
     * @notice Issued when a new prover is placed under consideration for acceptance
     *         into the Reliquary
     * @param prover the address of the prover contract
     * @param version the proposed identifier to always be associated with the prover
     * @param timestamp the earliest this prover can be brought into the Reliquary
     */
    event PendingProverAdded(address prover, uint64 version, uint64 timestamp);

    /**
     * @notice Issued when an existing prover is banished from the Reliquary
     * @param prover the address of the prover contract
     * @param version the identifier that can never be used again
     * @dev revoked provers may not issue new Relics or Artifacts. The meaning of
     *      any previously introduced Relics or Artifacts is implementation dependent.
     */
    event ProverRevoked(address prover, uint64 version);

    /**
     * @notice Helper function to parse fact storage
     * @param fact The data associated with the proven Relic or Artifact
     * @return version the version identifier of the prover who introduced this item
     * @return data any data associated with this item
     */
    function parseFact(bytes storage fact)
        internal
        pure
        returns (uint64 version, bytes memory data)
    {
        // copy the storage bytes to memory
        data = fact;

        if (data.length > 0) {
            require(data.length >= 8, "fact data length invalid");

            // version is stored in first 8 bytes of the data
            version = uint64(bytes8(data));

            // rather than copy the rest of the data to a new bytes array,
            // just point data to data + 8 and setup length field
            assembly {
                let len := mload(data)
                data := add(data, 8)
                mstore(data, sub(len, 8))
            }
        }
    }

    /**
     * @notice Helper function to query the status of a prover
     * @param prover the ProverInfo associated with the prover in question
     * @dev reverts if the prover is invalid or revoked
     */
    function checkProver(ProverInfo memory prover) public pure {
        require(prover.revoked != true, "revoked prover");
        require(prover.version != 0, "unknown prover");
    }

    /**
     * @notice Deletes the fact from the Reliquary
     * @param account The account to which this information is bound (may be
     *        the null account for information bound to no specific address)
     * @param factSig The unique signature of the particular fact being deleted
     * @dev May only be called by non-revoked provers
     */
    function resetFact(address account, FactSignature factSig) external {
        ProverInfo memory prover = provers[msg.sender];
        checkProver(prover);

        delete provenFacts[account][factSig];
    }

    /**
     * @notice Adds the given information to the Reliquary
     * @param account The account to which this information is bound (may be
     *        the null account for information bound to no specific address)
     * @param factSig The unique signature of the particular fact being proven
     * @param data Associated data to store with this item
     * @dev May only be called by non-revoked provers
     */
    function setFact(
        address account,
        FactSignature factSig,
        bytes calldata data
    ) external {
        ProverInfo memory prover = provers[msg.sender];
        checkProver(prover);

        provenFacts[account][factSig] = abi.encodePacked(prover.version, data);
    }

    /**
     * @notice Query for associated information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev This function is only for use by provers (reverts otherwise)
     */
    function getFact(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        )
    {
        ProverInfo memory prover = provers[msg.sender];
        checkProver(prover);

        (version, data) = parseFact(provenFacts[account][factSig]);
        exists = version != 0;
    }

    /**
     * @notice Query for associated information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev This function is only for use by the Reliquary itself
     */
    function _verifyFact(address account, FactSignature factSig)
        internal
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        )
    {
        (version, data) = parseFact(provenFacts[account][factSig]);
        exists = version != 0;
    }

    /**
     * @notice Query for some information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @dev This function is only for use by the Reliquary itself
     */
    function _verifyFactVersion(address account, FactSignature factSig)
        internal
        view
        returns (bool exists, uint64 version)
    {
        version = uint64(bytes8(provenFacts[account][factSig]));
        exists = version != 0;
    }

    /**
     * @notice Query for associated information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev This function is for use by anyone
     * @dev This function reverts if the fact requires a fee to query
     */
    function verifyFactNoFee(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        )
    {
        require(Facts.toFactClass(factSig) == Facts.NO_FEE);
        return _verifyFact(account, factSig);
    }

    /**
     * @notice Query for some information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @dev This function is for use by anyone
     * @dev This function reverts if the fact requires a fee to query
     */
    function verifyFactVersionNoFee(address account, FactSignature factSig)
        external
        view
        returns (bool exists, uint64 version)
    {
        require(Facts.toFactClass(factSig) == Facts.NO_FEE);
        return _verifyFactVersion(account, factSig);
    }

    /**
     * @notice Verify if a particular block had a particular hash
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @return boolean indication of whether or not the given block was
     *         proven to have the given hash.
     * @dev This function is only for use by provers (reverts otherwise)
     */
    function validBlockHashFromProver(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes calldata proof
    ) public view returns (bool) {
        ProverInfo memory proverInfo = provers[msg.sender];
        checkProver(proverInfo);
        return IBlockHistory(verifier).validBlockHash(hash, num, proof);
    }

    /**
     * @notice Asserts that a particular block had a particular hash
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @dev Reverts if the given block was not proven to have the given hash.
     * @dev This function is only for use by provers (reverts otherwise)
     */
    function assertValidBlockHashFromProver(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes calldata proof
    ) external view {
        require(validBlockHashFromProver(verifier, hash, num, proof), "invalid block hash");
    }

    /**
     * @notice Query for associated information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev This function is for use by off-chain tools only (reverts otherwise)
     */
    function debugVerifyFact(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        )
    {
        require(tx.origin == address(0));
        return _verifyFact(account, factSig);
    }

    /**
     * @notice Verify if a particular block had a particular hash
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @return boolean indication of whether or not the given block was
     *         proven to have the given hash.
     * @dev This function is for use by off-chain tools only (reverts otherwise)
     */
    function debugValidBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes calldata proof
    ) external view returns (bool) {
        require(tx.origin == address(0));
        return IBlockHistory(verifier).validBlockHash(hash, num, proof);
    }

    /*
     * Allow a new prover to produce facts. Provers must have distinct versions.
     *
     * Once added, a new prover is not usable until it is activated after a short delay. This delay
     * prevents future governance from abusing its powers, and gives downstream users an
     * opportunity to decide if they still trust Reliquary.
     */
    /**
     * @notice Add/propose a new prover to prove facts.
     * @param prover the address of the prover in question
     * @param version the unique version string to associate with this prover
     * @dev Provers and proposed provers must have unique version IDs
     * @dev After the Reliquary is initialized, a review period of 64k blocks
     *      must conclude before a prover may be added. The request must then
     *      be re-submitted to take effect. Before initialization is complete,
     *      the review period is skipped.
     * @dev Pending provers may be removed by submitting a new prover with a
     *      version of 0.
     * @dev Emits PendingProveRemoved when a pending prover proposal is withdrawn
     * @dev Emits NewProver when a prover is added to the reliquary
     * @dev Emits PendingProverAdded when a prover is proposed for inclusion
     */
    function addProver(address prover, uint64 version) external onlyRole(ADD_PROVER_ROLE) {
        require(version != 0, "version must not be zero");
        require(versions[version] == address(0), "duplicate version");
        require(provers[prover].version == 0, "duplicate prover");
        require(pendingProvers[prover].version == 0, "already pending");

        uint256 delay = initialized ? DELAY : 0;
        PendingProver memory pendingProver = PendingProver(
            uint64(block.timestamp + delay),
            version
        );
        pendingProvers[prover] = pendingProver;

        // Pre-initialize ProverInfo so fee can be set before activation
        // As version = 0, the prover will not be usable yet
        provers[prover] = ProverInfo(0, FeeInfo(0, 0, 0, 0, 0), false);

        emit PendingProverAdded(prover, pendingProver.version, pendingProver.timestamp);
    }

    /* Anyone can activate a prover once it has been added and is no longer pending */
    function activateProver(address prover) external {
        require(provers[prover].version == 0, "duplicate prover");

        PendingProver memory pendingProver = pendingProvers[prover];
        require(pendingProver.version != 0, "invalid address");
        require(pendingProver.timestamp <= block.timestamp, "not ready");
        require(versions[pendingProver.version] == address(0), "duplicate version");

        versions[pendingProver.version] = prover;
        provers[prover].version = pendingProver.version;

        emit NewProver(prover, pendingProver.version);
    }

    /**
     * @notice Stop accepting proofs from this prover
     * @param prover The prover to banish from the reliquary
     * @dev Emits ProverRevoked
     * @dev Note: existing facts proved by the prover may still stand
     */
    function revokeProver(address prover) external onlyRole(GOVERNANCE_ROLE) {
        provers[prover].revoked = true;
        emit ProverRevoked(prover, pendingProvers[prover].version);
    }

    /**
     * @notice Initialize the Reliquary, enforcing the time lock for new provers
     */
    function setInitialized() external onlyRole(ADD_PROVER_ROLE) {
        initialized = true;
    }
}