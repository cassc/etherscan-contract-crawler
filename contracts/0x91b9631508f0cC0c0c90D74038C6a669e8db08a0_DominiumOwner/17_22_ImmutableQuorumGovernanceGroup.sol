//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IGovernance} from "../../interfaces/IGovernance.sol";

import {LibEIP712} from "../../libraries/LibEIP712.sol";
import {LibPercentage} from "../../libraries/LibPercentage.sol";
import {LibSignature} from "../../libraries/LibSignature.sol";

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title Multi-sig quorum governance based immutable group
/// @author Amit Molek
/// @dev Please see `IGovernance`.
/// Each owner gets an equal vote. To verify a hash, a minimum number
/// of approve votes MUST be present.
/// The minimum group size is 3: 1 is not a group and 2 it risky (1 stolen account can cause harm)
/// And the quorum threshold is 60%.
contract ImmutableQuorumGovernanceGroup is IGovernance, ERC165 {
    using EnumerableSet for EnumerableSet.AddressSet;

    /* CONSTANTS */

    /// @dev Minimum number of owners at any time
    uint256 public constant MIN_OWNERS_LENGTH = 3;
    /// @dev Percentage of how many owners MUST sign the hash to verify it
    /// e.g. 3 owners, 60% => 60% out of 3 is 2, so 2 owners must sign
    uint256 public constant QUORUM_THRESHOLD_PERCENTAGE = 60; // 60%

    /* FIELDS */

    /// @dev Minimum number of signatures needed to verify a hash
    uint256 public quorumGovernanceThreshold;

    /// @dev Set of owners
    EnumerableSet.AddressSet internal _owners;

    /* ERRORS */

    /// @dev Not enough owners to initialize the contract (see MIN_OWNERS_LENGTH)
    error MinimumOwners();

    /// @dev Unknown or invalid owner (Not an owner, zero address...)
    /// @param account The account in question
    error InvalidOwner(address account);

    /// @dev Owner already exist
    /// @param account The duplicated account
    error DuplicateOwner(address account);

    /// @dev Recevied invalid signatures (Unsorted)
    error InvalidSignatures();

    /// @dev Unverified hash. Not enough owners signed to reach the quorum threshold
    /// @param hash The hash in question
    error UnapprovedHash(bytes32 hash);

    constructor(address[] memory owners) {
        LibEIP712._initDomainSeparator();
        _initOwners(owners);
    }

    /// @param signatures must be sorted by address
    function verifyHash(bytes32 hash, bytes[] memory signatures)
        public
        view
        override
        returns (bool)
    {
        uint256 length = signatures.length;
        address prevSigner = address(0);
        address signer;
        uint256 validSignaturesCount;

        // Iterate over the signatures and count the valid ones
        for (uint256 i = 0; i < length; i++) {
            // Check for duplicates
            signer = LibSignature._recoverSigner(hash, signatures[i]);
            if (signer <= prevSigner) {
                revert InvalidSignatures();
            }
            prevSigner = signer;

            // Verify that the signer is an owner
            if (_owners.contains(signer) == false) {
                revert InvalidOwner(signer);
            }

            validSignaturesCount++;
        }

        return validSignaturesCount >= quorumGovernanceThreshold;
    }

    /// @return How many owners are in the group
    function ownersLength() external view returns (uint256) {
        return _owners.length();
    }

    /// @return Owner at index `i`
    function ownerAt(uint256 i) external view returns (address) {
        return _owners.at(i);
    }

    /// @return true, if `account` is an owner
    function isOwner(address account) external view returns (bool) {
        return _owners.contains(account);
    }

    /// @dev Reverts with `UnapprovedHash` if `hash` can't be verified using `signatures`
    function _verifyHashGuard(bytes32 hash, bytes[] memory signatures)
        internal
        view
    {
        if (verifyHash(hash, signatures) == false) {
            revert UnapprovedHash(hash);
        }
    }

    /// @dev Initialize owner set and quorum threshold
    function _initOwners(address[] memory owners) internal {
        if (owners.length < MIN_OWNERS_LENGTH) {
            revert MinimumOwners();
        }

        uint256 length = owners.length;
        for (uint256 i = 0; i < length; i++) {
            address owner = owners[i];

            if (owner == address(0)) {
                revert InvalidOwner(owner);
            }

            // Add owner
            bool success = _owners.add(owner);
            if (success == false) {
                revert DuplicateOwner(owner);
            }
        }

        // Calculate the quorum threshold
        quorumGovernanceThreshold = _calculateQuorumGovernanceThreshold(length);
    }

    /// @return The quorum threshold (see `quorumGovernanceThreshold`)
    function _calculateQuorumGovernanceThreshold(uint256 ownerLength)
        internal
        pure
        returns (uint256)
    {
        return
            LibPercentage._calculateCeil(
                ownerLength,
                QUORUM_THRESHOLD_PERCENTAGE
            );
    }

    /* ERC165 */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IGovernance).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}