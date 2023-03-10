// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IMoonbirds} from "moonbirds/IMoonbirds.sol";
import {MerkleProof} from
    "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";

/**
 * @notice Base contract for airdrops claimable by a subset of nested birds.
 */
abstract contract NestedMerkleClaimableBase {
    using MerkleProof for bytes32[];

    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Thrown if the caller is not allowed to claim the airdrop for a
     * given moonbird.
     */
    error NotAllowedToClaim(uint256 birbId);

    /**
     * @notice Thrown if a moonbird was already used to claim the airdrop.
     */
    error AlreadyClaimed(uint256 birbId);

    /**
     * @notice Thrown if the claiming moonbird is not nested.
     */
    error NotNested(uint256 birbId);

    /**
     * @notice Thrown if the claiming moonbird was nested after the deadline.
     */
    error NestedTooLate(uint256 birbId);

    /**
     * @notice Thrown if a provided merkle proof has incorrect length.
     */
    error InvalidProofLength();

    /**
     * @notice Thrown if the merkle proof stating that a moonbird is eligible
     * for the airdrop is not correct.
     */
    error IncorrectProof(uint256 birbId);

    /**
     * @notice Thrown if the airdrop is not yet open for claims.
     */
    error NestedMerkleClaimDisabled();

    /**
     * @notice Thrown if the steerer attempts to open the merkle claim for
     * nested birds if no nesting timestamp has been set.
     */
    error CannotOpenNestedMerkleClaimWithoutTimestamp();

    /**
     * @notice Thrown if the steerer attempts to reset the nesting timestamp.
     */
    error CannotResetNestedBeforeTimestamp();

    // =========================================================================
    //                           Constants
    // =========================================================================

    /**
     * @notice The merkle root of all eligible moonbird tokenIds.
     */
    bytes32 public immutable eligibleMoonbirdsRoot;

    /**
     * @notice The length of valid merkle proofs.
     * @dev This is deliberately fixed to prevent merkle proof malleability
     * vulnerabilities.
     */
    uint256 internal immutable _proofLength;

    /**
     * @notice The moonbirds contract.
     */
    IMoonbirds internal immutable _moonbirds;

    /**
     * @notice Flag to enable/disable the nesting check.
     */
    bool internal immutable _mustBeNested;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice Tracks Moonbirds that have already been used to claim vouchers.
     */
    mapping(uint256 => bool) private _hasClaimed;

    /**
     * @notice The timestamp at which the claim was opened.
     * @dev Moonbirds nested after this timestamp can no longer claim the
     * airdrop.
     */
    uint248 public nestedBeforeTimestamp;

    /**
     * @notice Flag to enable/disable the claim.
     */
    bool private _claimEnabled;

    // =========================================================================
    //                           Constructor
    // =========================================================================
    constructor(
        IMoonbirds moonbirds,
        bytes32 eligibleMoonbirdsRoot_,
        uint256 proofLength_,
        bool mustBeNested_
    ) {
        _moonbirds = moonbirds;
        eligibleMoonbirdsRoot = eligibleMoonbirdsRoot_;
        _proofLength = proofLength_;
        _mustBeNested = mustBeNested_;
    }

    // =========================================================================
    //                           Claiming
    // =========================================================================

    /**
     * @notice A moonbird token with merkle proof prove that it is in the
     * eligible set.
     */
    struct MerkleBird {
        uint256 tokenId;
        bytes32[] merkleProof;
    }

    /**
     * @notice Interface to claim airdrops for a given moonbirds.
     * @param merkleBirds Moonbirds with proofs that they are eligible for the
     * airdrop.
     * @dev Reverts if the caller is not allowed to claim the airdrop. (Usually
     * if the the sender is neither the owner of nor approved to transfer the
     * claiming moonbird).
     * @dev Reverts if the moonbird is not nested or was nested after the
     * opening timestamp.
     */
    function claimMultipleWithNestedMerkle(MerkleBird[] calldata merkleBirds)
        external
        onlyIfNestedMerkleClaimEnabled
    {
        for (uint256 i; i < merkleBirds.length; ++i) {
            _claimWithNestedMerkle(
                merkleBirds[i].tokenId, merkleBirds[i].merkleProof
            );
        }
    }

    /**
     * @notice Processes the claim of an airdrop for a given moonbird.
     * @param birbId The id of the moonbird for which the airdrop should be
     * claimed.
     * @param merkleProof Proof that the moonbird is eligible for the airdrop.
     * @dev Reverts if the caller is not allowed to claim the airdrop. (Usually
     * if the the sender is neither the owner of nor approved to transfer the
     * claiming moonbird).
     * @dev Reverts if the moonbird is not nested or was nested after the
     * opening timestamp.
     */
    function _claimWithNestedMerkle(
        uint256 birbId,
        bytes32[] calldata merkleProof
    ) internal {
        if (merkleProof.length != _proofLength) {
            revert InvalidProofLength();
        }

        if (!merkleProof.verify(eligibleMoonbirdsRoot, bytes32(birbId))) {
            revert IncorrectProof(birbId);
        }

        if (!_isAllowedToClaimWithNestedMerkle(msg.sender, birbId)) {
            revert NotAllowedToClaim(birbId);
        }

        if (_mustBeNested) {
            (bool nesting, uint256 nestingPeriod,) =
                _moonbirds.nestingPeriod(birbId);
            if (!nesting) {
                revert NotNested(birbId);
            }

            // solhint-disable-next-line not-rely-on-time
            if (block.timestamp > nestedBeforeTimestamp + nestingPeriod) {
                revert NestedTooLate(birbId);
            }
        }

        if (_hasClaimed[birbId]) {
            revert AlreadyClaimed(birbId);
        }
        _hasClaimed[birbId] = true;

        _doClaimWithNestedMerkle(msg.sender, birbId);
    }

    /**
     * @notice Ensures that the wrapped function can only be called if the
     * nested merkle claim is enabled.
     */
    modifier onlyIfNestedMerkleClaimEnabled() {
        if (!_claimEnabled) {
            revert NestedMerkleClaimDisabled();
        }
        _;
    }

    /**
     * @notice Returns if the airdrop was already claimed for a given moonbird.
     */
    function hasClaimed(uint256 birbId) public view returns (bool) {
        return _hasClaimed[birbId];
    }

    // =========================================================================
    //                           Steering
    // =========================================================================

    /**
     * @notice Opens the claim of the airdrop.
     * @dev `nestedBeforeTimestamp` must be set before calling this function if
     * the moonbirds nesting check is enabled.
     */
    function _toggleNestedMerkleClaim(bool toggle) internal {
        if (nestedBeforeTimestamp == 0 && _mustBeNested) {
            revert CannotOpenNestedMerkleClaimWithoutTimestamp();
        }
        _claimEnabled = toggle;
    }

    /**
     * @notice Set the timestamp before which moonbirds must have been nested to
     * be eligible for the airdrop.
     * @dev
     */
    function _setNestedBeforeTimestamp(uint256 nestedBeforeTimestamp_)
        internal
    {
        if (nestedBeforeTimestamp != 0) {
            revert CannotResetNestedBeforeTimestamp();
        }
        nestedBeforeTimestamp = uint248(nestedBeforeTimestamp_);
    }

    // =========================================================================
    //                           Internals
    // =========================================================================

    /**
     * @notice Hook called by `_claimWithNestedMerkle` to preform the airdrop
     * for a given moonbird (e.g. minting a voucher token to the caller).
     */
    function _doClaimWithNestedMerkle(address receiver, uint256 birbId)
        internal
        virtual;

    /**
     * @notice Hook called by `_claimWithNestedMerkle` to check if an operator
     * can claim the airdrop for a given moonbird.
     */
    function _isAllowedToClaimWithNestedMerkle(
        address operator,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        return _isApprovedForOrOwnerOfMoonbird(operator, tokenId);
    }

    /**
     * @notice Returns if an operator is the owner of or approved to transfer
     * a given moonbird.
     */
    function _isApprovedForOrOwnerOfMoonbird(address operator, uint256 tokenId)
        internal
        view
        returns (bool result)
    {
        address tokenOwner = _moonbirds.ownerOf(tokenId);
        return (operator == tokenOwner)
            || (operator == _moonbirds.getApproved(tokenId))
            || _moonbirds.isApprovedForAll(tokenOwner, operator);
    }
}