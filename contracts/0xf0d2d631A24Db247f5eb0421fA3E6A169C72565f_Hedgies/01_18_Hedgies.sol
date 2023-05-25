/*

    Copyright 2022 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ERC721 }  from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable }  from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { HedgiesRoles } from "./HedgiesRoles.sol";

/**
 * @title Hedgies
 * @author dYdX
 *
 * @notice The Hedgies NFT contract.
 */
contract Hedgies is
    HedgiesRoles,
    ERC721Enumerable,
    Pausable
{
    //  ============ Structs ============

    struct MerkleRoot {
        bytes32 merkleRoot;
        bytes ipfsCid;
    }

    struct TierMintingInformation {
        uint256 unlockTimestamp;
        uint256 maxSupply;
    }

    // ============ Events ============

    event StartingIndexBlockSet(
        uint256 startingIndexBlock
    );

    event StartingIndexValueSet(
        uint256 startingIndexValue
    );

    event BaseURISet(
        string baseURI
    );

    event MerkleRootSet(
        MerkleRoot merkleRoot
    );

    event DistributionMintRateSet(
        uint256 distributionMintRate
    );

    event DistributionOffsetSet(
        uint256 distributionOffset
    );

    event FinalizedUri();

    // ============ Constants ============

    uint256 constant public NUM_TIERS = 3;

    uint256 constant public DISTRIBUTION_BASE = 10 ** 18;

    bytes32 immutable public PROVENANCE_HASH;

    uint256 immutable public MAX_SUPPLY;

    uint256 immutable public RESERVE_SUPPLY;

    uint256 immutable public TIER_ZERO_MINTS_UNLOCK_TIMESTAMP;

    uint256 immutable public TIER_ONE_MINTS_UNLOCK_TIMESTAMP;

    uint256 immutable public TIER_TWO_MINTS_UNLOCK_TIMESTAMP;

    uint256 immutable public TIER_ZERO_MINTS_MAX_SUPPLY;

    uint256 immutable public TIER_ONE_MINTS_MAX_SUPPLY;

    uint256 immutable public TIER_TWO_MINTS_MAX_SUPPLY;

    // ============ State Variables ============

    MerkleRoot public _MERKLE_ROOT_;

    uint256 public _HEDGIE_DISTRIBUTION_MINT_RATE_;

    uint256 public _HEDGIE_DISTRIBUTION_OFFSET_;

    string public _BASE_URI_ = "";

    bool public _URI_IS_FINALIZED_ = false;

    mapping (address => bool) public _HAS_CLAIMED_HEDGIE_;

    uint256 public _STARTING_INDEX_BLOCK_ = 0;

    // Note: Packed into a shared storage slot.
    bool public _STARTING_INDEX_SET_ = false;
    uint248 public _STARTING_INDEX_VALUE_ = 0;

    // ============ Constructor ============

    constructor(
        string[2] memory nameAndSymbol,
        bytes32 provenanceHash,
        uint256 reserveSupply,
        bytes32 merkleRoot,
        bytes memory ipfsCid,
        uint256[3] memory mintTierTimestamps,
        uint256[3] memory mintTierMaxSupplies,
        uint256 maxSupply,
        address[3] memory roleOwners,
        uint256[2] memory mintToVariables
    )
        HedgiesRoles(roleOwners[0], roleOwners[1], roleOwners[2])
        ERC721(nameAndSymbol[0], nameAndSymbol[1])
    {
        // Verify the mint tier information is all correct.
        require(
            (
                reserveSupply <= mintTierMaxSupplies[0] &&
                mintTierMaxSupplies[0] <= mintTierMaxSupplies[1] &&
                mintTierMaxSupplies[1] <= mintTierMaxSupplies[2] &&
                mintTierMaxSupplies[2] <= maxSupply
            ),
            "Each mint tier must gte the previous, includes reserveSupply and maxSupply"
        );
        require(
            (
                mintTierTimestamps[0] < mintTierTimestamps[1] &&
                mintTierTimestamps[1] < mintTierTimestamps[2]
            ),
            "Each tier must unlock later than the previous one"
        );

        // Set the provenanceHash.
        PROVENANCE_HASH = provenanceHash;

        // Set the maxSupply.
        MAX_SUPPLY = maxSupply;

        // The reserve supply is the number of hedgies set aside for the team and giveaways.
        RESERVE_SUPPLY = reserveSupply;

        // The tier mint unlock timestamps.
        TIER_ZERO_MINTS_UNLOCK_TIMESTAMP = mintTierTimestamps[0];
        TIER_ONE_MINTS_UNLOCK_TIMESTAMP = mintTierTimestamps[1];
        TIER_TWO_MINTS_UNLOCK_TIMESTAMP = mintTierTimestamps[2];

        // The tier max supplies.
        TIER_ZERO_MINTS_MAX_SUPPLY = mintTierMaxSupplies[0];
        TIER_ONE_MINTS_MAX_SUPPLY = mintTierMaxSupplies[1];
        TIER_TWO_MINTS_MAX_SUPPLY = mintTierMaxSupplies[2];

        // Set the merkle-root for eligible minters.
        _setMerkleRootAndCid(
            merkleRoot,
            ipfsCid
        );

        // Set the hedgie distribution information.
        _setDistributionMintRate(mintToVariables[0]);
        _setDistributionOffset(mintToVariables[1]);
    }

    // ============ Modifiers ============

    modifier uriNotFinalized {
        // Verify the sale has not been finalized.
        require(
            !_URI_IS_FINALIZED_,
            'Cannot update once the sale has been finalized'
        );
        _;
    }

    // ============ External Admin-Only Functions ============

    /**
     * @notice Pause this contract.
     */
    function pause()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _pause();
    }

    /**
     * @notice Unpause this contract.
     */
    function unpause()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _unpause();
    }

    /**
     * @notice Set the sale of the collection as finalized, preventing the baseURI from
     * being updated again.
     * @dev Emits finalized event.
     */
    function finalize()
        external
        uriNotFinalized
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _URI_IS_FINALIZED_ = true;
        emit FinalizedUri();
    }

    /**
     * @notice Mint a hedgie to a specific address up to the reserve supply.
     *
     * Important: The reserve supply should be minted before the sale is enabled.
     *
     * @param  maxMint    The maximum number of NFTs to mint in one call to the function.
     * @param  recipient  The address to mint the token to.
     */
    function reserveHedgies(
        uint256 maxMint,
        address recipient
    )
        external
        whenNotPaused
        onlyRole(RESERVER_ROLE)
    {
        // Get supply and NFTs to mint.
        uint256 supply = totalSupply();
        uint256 hedgiesToMint = Math.min(maxMint, RESERVE_SUPPLY - supply);
        require(
            hedgiesToMint > 0,
            "Cannot premint once max premint supply has been reached"
        );

        // Mint each NFT sequentially.
        for (uint256 i = 0; i < hedgiesToMint; i++) {
            // Use _mint() instead of _safeMint() since we don't plan to mint to any smart contracts.
            _mint(recipient, supply + i);
        }
    }

    /**
     * @notice Mint a hedgie to a specific address.
     *
     * @param  recipient  The address to mint the token to.
     * @param  tokenId    The id of the token to mint.
     */
    function mintHedgieTo(
        address recipient,
        uint256 tokenId
    )
        external
        whenNotPaused
        onlyRole(MINTER_ROLE)
    {
        // Do not mint tokenId that should have been minted by now.
        require(
            tokenId >= TIER_TWO_MINTS_MAX_SUPPLY,
            "Cannot mint token with tokenId lte tier two maxSupply"
        );

        // Do not mint tokens with invalid tokenIds.
        // Prevents supply > MAX_SUPPLY as no duplicate tokenIds are allowed either.
        require(
            tokenId < MAX_SUPPLY,
            "Cannot mint token with tokenId greater than maxSupply"
        );

        uint256 supply = totalSupply();

        // Do not begin minting until all hedgies from tier 2 are minted.
        require(
            supply >= TIER_TWO_MINTS_MAX_SUPPLY,
            "Cannot mint token for distribution before sale has completed"
        );

        // Verify that the maximum distributable supply at this timestamp has not been exceeded.
        // Note: If _HEDGIE_DISTRIBUTION_OFFSET_ >= block.timestamp this call will revert.
        uint256 availableHedgiesToMint = (
            _HEDGIE_DISTRIBUTION_MINT_RATE_* (
                block.timestamp - _HEDGIE_DISTRIBUTION_OFFSET_
            ) / DISTRIBUTION_BASE
        );
        require(
            supply < availableHedgiesToMint + TIER_TWO_MINTS_MAX_SUPPLY,
            'At the current timestamp supply is capped for distributing'
        );

        // Use _mint() instead of _safeMint() since we don't plan to mint to any smart contracts.
        _mint(recipient, tokenId);
    }

    /**
     * @notice Set the mint rate to distribute Hedgies at.
     * @dev Emits DistributionMintRateSet event from an internal call.
     *
     * @param  distributionMintRate  The mint rate to distribute Hedgies at.
     */
    function setDistributionMintRate(
        uint256 distributionMintRate
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDistributionMintRate(distributionMintRate);
    }

    /**
     * @notice Set the offset for the mint rate to distribute Hedgies at. This is the timestamp at
     * which we consider distribution via mintHedgieTo to have started.
     * @dev Emits DistributionOffsetSet event from an internal call.
     *
     * @param  distributionOffset  The offset for the mint rate to distribute Hedgies at.
     */
    function setDistributionOffset(
        uint256 distributionOffset
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDistributionOffset(distributionOffset);
    }

    /**
     * @notice Set the base URI which determines the metadata URI for all tokens.
     * Note: this call will revert if the contract is finalized.
     * @dev Emits BaseURISet event.
     *
     * @param  baseURI  The URI that determines the metadata URI for all tokens.
     */
    function setBaseURI(
        string calldata baseURI
    )
        external
        uriNotFinalized
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // Set the base URI.
        _BASE_URI_ = baseURI;
        emit BaseURISet(baseURI);
    }

    /**
     * @notice Update the Merkle root and CID for the minting tiers. This should not be necessary
     *  since these values should be set when the contract is constructed. This function is
     *  provided just in case.
     * @dev Emits MerkleRootSet event from an internal call.
     *
     * @param  merkleRoot  The root of the Merkle tree that proves who is eligible for distribution.
     * @param  ipfsCid     The content identifier in IPFS for the Merkle tree.
     */
    function setMerkleRootAndCid(
        bytes32 merkleRoot,
        bytes calldata ipfsCid
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setMerkleRootAndCid(merkleRoot, ipfsCid);
    }

    // ============ Other External Functions ============

    /**
     * @notice Mint a Hedgie if the tier 1 supply has not been reached. If we haven't set the starting index
     *  and this is the last token to be sold from tier 1, set the starting index block.
     * @dev Emits StartingIndexBlockSet event from an internal call.
     *
     * @param  tier         The tier of the account minting a Hedgie.
     * @param  merkleProof  The proof verifying the account is in the tier they are claiming to be in.
     */
    function mintHedgie(
        uint256 tier,
        bytes32[] calldata merkleProof
    )
        external
        whenNotPaused
    {
        // Get the tier minting information and verify that it is past the time when tier minting started.
        TierMintingInformation memory tierMintingInformation = getMintsAndMintTimeForTier(tier);
        require(
            block.timestamp >= tierMintingInformation.unlockTimestamp,
            "Tier minting is not yet allowed"
        );

        uint256 mintIndex = totalSupply();

        // Verify the reserve supply has been minted.
        require(
            mintIndex >= RESERVE_SUPPLY,
            "Not all Hedgies from the reserve supply have been minted"
        );

        // Verify the mint index is not past the max supply for the tier.
        // Note: First ID to be minted is 0, and last to be minted is TIER_TWO_MINTS_MAX_SUPPLY - 1.
        require(
            mintIndex < tierMintingInformation.maxSupply,
            "No Hedgies left to mint at this tier"
        );

        // The final tier is open to all.
        if (tier < NUM_TIERS - 1) {
            // Verify the address has not already minted.
            require(
                !_HAS_CLAIMED_HEDGIE_[msg.sender],
                'Sender already claimed'
            );

            // Check if address is in the tier. The final tier is open to all.
            require(
                isAddressEligible(msg.sender, tier, merkleProof),
                'Invalid Merkle proof'
            );

            // Mark the sender as having claimed.
            _HAS_CLAIMED_HEDGIE_[msg.sender] = true;
        }

        // Use _mint() instead of _safeMint() since any contract calling this must be directly doing so.
        _mint(msg.sender, mintIndex);

        // Set the starting index block automatically when minting the last token.
        if (mintIndex == TIER_TWO_MINTS_MAX_SUPPLY - 1) {
            _setStartingIndexBlock(block.number);
        }
    }

    /**
     * @notice Set the starting index using the previously determined block number.
     * @dev Emits StartingIndexBlockSet event from an internal call and StartingIndexValueSet event.
     */
    function setStartingIndex()
        external
    {
        // Verify the starting index has not been set.
        require(
            !_STARTING_INDEX_SET_,
            "Starting index is already set"
        );

        // Verify the starting block has already been set.
        uint256 startingIndexBlock = _STARTING_INDEX_BLOCK_;
        require(
            startingIndexBlock != 0,
            "Starting index block must be set"
        );

        // Ensure the starting index block is within 256 blocks exclusive of the previous block
        // and is not the current block as it has no blockHash yet.
        // https://docs.soliditylang.org/en/v0.8.11/units-and-global-variables.html#block-and-transaction-properties
        uint256 prevBlock = block.number - 1;
        uint256 blockDifference = prevBlock - startingIndexBlock;

        // If needed, set the starting index block to be within 256 of the current block.
        if (blockDifference >= 256) {
            startingIndexBlock = prevBlock - (blockDifference % 256);
            _setStartingIndexBlock(startingIndexBlock);
        }

        // Set the starting index.
        uint248 startingIndexValue = uint248(
            uint256(blockhash(startingIndexBlock)) % MAX_SUPPLY
        );

        // Note: Packed into a shared storage slot.
        _STARTING_INDEX_VALUE_ = startingIndexValue;
        _STARTING_INDEX_SET_ = true;
        emit StartingIndexValueSet(startingIndexValue);
    }

    // ============ Public Functions ============

    /**
     * @notice Get params for a minting tier: the unlock timestamp and number of mints available.
     *
     * @param  tier  The tier being checked for its unlock timestamp and number of total mints.
     */
    function getMintsAndMintTimeForTier(
        uint256 tier
    )
        public
        view
        returns (TierMintingInformation memory)
    {
        // Verify the tier is a valid mint tier.
        require(
            tier < NUM_TIERS,
            "Invalid tier provided"
        );

        // Return the information for the tier being requested.
        if (tier == 0) {
            return TierMintingInformation({
                unlockTimestamp: TIER_ZERO_MINTS_UNLOCK_TIMESTAMP,
                maxSupply: TIER_ZERO_MINTS_MAX_SUPPLY
            });
        }
        if (tier == 1) {
            return TierMintingInformation({
                unlockTimestamp: TIER_ONE_MINTS_UNLOCK_TIMESTAMP,
                maxSupply: TIER_ONE_MINTS_MAX_SUPPLY
            });
        }
        return TierMintingInformation({
            unlockTimestamp: TIER_TWO_MINTS_UNLOCK_TIMESTAMP,
            maxSupply: TIER_TWO_MINTS_MAX_SUPPLY
        });
    }

    /**
     * @notice Check if an address is eligible for a given tier.
     *
     * @param  ethereumAddress  The address trying to mint a hedige.
     * @param  tier             The tier to check.
     * @param  merkleProof      The Merkle proof proving that (ethereumAddress, tier) is in the tree.
     */
    function isAddressEligible(
        address ethereumAddress,
        uint256 tier,
        bytes32[] calldata merkleProof
    )
        public
        view
        returns (bool)
    {
        // Get the node of the ethereumAddress and tier and verify it is in the Merkle tree.
        bytes32 node = keccak256(abi.encodePacked(ethereumAddress, tier));
        return MerkleProof.verify(merkleProof, _MERKLE_ROOT_.merkleRoot, node);
    }

    /**
     * @notice See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC721Enumerable)
        returns (bool)
    {
        return (
            AccessControl.supportsInterface(interfaceId) ||
            ERC721Enumerable.supportsInterface(interfaceId)
        );
    }

    // ============ Internal Functions ============

    /**
     * @notice Get the base URI.
     */
    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        // Get the base URI.
        return _BASE_URI_;
    }

    /**
     * @notice Set the starting index.
     * @dev Emits StartingIndexBlockSet event.
     *
     * @param  startingIndexBlock  The block number to set the starting index to.
     */
    function _setStartingIndexBlock(
        uint256 startingIndexBlock
    )
        internal
    {
        _STARTING_INDEX_BLOCK_ = startingIndexBlock;
        emit StartingIndexBlockSet(startingIndexBlock);
    }

    /**
     * @notice Set the merkle root and CID.
     * @dev Emits MerkleRootSet event.
     *
     * @param  merkleRoot  The root of the Merkle tree that proves who is eligible for distribution.
     * @param  ipfsCid     The content identifier in IPFS for the Merkle tree data.
     */
    function _setMerkleRootAndCid(
        bytes32 merkleRoot,
        bytes memory ipfsCid
    )
        internal
    {
        // Get the full Merkle root and set _MERKLE_ROOT_ in storage.
        MerkleRoot memory fullMerkleRoot = MerkleRoot({
            merkleRoot: merkleRoot,
            ipfsCid: ipfsCid
        });
        _MERKLE_ROOT_ = fullMerkleRoot;
        emit MerkleRootSet(fullMerkleRoot);
    }

    /**
     * @notice Set the mint rate to distribute Hedgies at.
     * @dev Emits DistributionMintRateSet event.
     *
     * @param  distributionMintRate  The mint rate to distribute Hedgies at.
     */
    function _setDistributionMintRate(
        uint256 distributionMintRate
    )
        internal
    {
        // Set the distribution mint rate.
        _HEDGIE_DISTRIBUTION_MINT_RATE_ = distributionMintRate;
        emit DistributionMintRateSet(distributionMintRate);
    }

    /**
     * @notice Set the offset for the mint rate to distribute Hedgies at. This is the timestamp at
     * which we consider distribution via mintHedgieTo to have started.
     * @dev Emits DistributionOffsetSet event.
     *
     * @param  distributionOffset  The offset for the mint rate to distribute Hedgies at.
     */
    function _setDistributionOffset(
        uint256 distributionOffset
    )
        internal
    {
        // Set the offset for the distribution mint rate.
        _HEDGIE_DISTRIBUTION_OFFSET_ = distributionOffset;
        emit DistributionOffsetSet(distributionOffset);
    }
}