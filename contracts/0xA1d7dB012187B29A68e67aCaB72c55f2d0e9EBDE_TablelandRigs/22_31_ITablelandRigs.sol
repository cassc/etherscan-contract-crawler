// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.10 <0.9.0;

import "./ITablelandRigPilots.sol";

/**
 * @dev Interface of a TablelandRigs compliant contract.
 */
interface ITablelandRigs {
    // Thrown when minting with minting not open.
    error MintingClosed();

    // Thrown when minting with quantity of zero.
    error ZeroQuantity();

    // Thrown when minting when mint quantity exceeds remaining allowance.
    error InsufficientAllowance();

    // Thrown when minting when an allowance proof is invalid.
    error InvalidProof();

    // Thrown when minting and mint txn value is too low.
    error InsufficientValue(uint256 price);

    // Thrown when minting when there are no more Rigs.
    error SoldOut();

    // Values describing mint phases.
    enum MintPhase {
        CLOSED,
        ALLOWLIST,
        WAITLIST,
        PUBLIC
    }

    /**
     * @dev Emitted when mint phase is changed.
     */
    event MintPhaseChanged(MintPhase mintPhase);

    /**
     * @dev Emitted when a buyer is refunded.
     */
    event Refund(address indexed buyer, uint256 amount);

    /**
     * @dev Emitted on all purchases of non-zero amount.
     */
    event Revenue(
        address indexed beneficiary,
        uint256 numPurchased,
        uint256 amount
    );

    /**
     * @dev Mints Rigs.
     *
     * quantity - the number of Rigs to mint
     *
     * Requirements:
     *
     * - contract must be unpaused
     * - quantity must not be zero
     * - contract mint phase must be `MintPhase.PUBLIC`
     */
    function mint(uint256 quantity) external payable;

    /**
     * @dev Mints Rigs from a whitelist.
     *
     * quantity - the number of Rigs to mint
     * freeAllowance - the number of free Rigs allocated to `msg.sender`
     * paidAllowance - the number of paid Rigs allocated to `msg.sender`
     * proof - merkle proof proving `msg.sender` has said `freeAllowance` and `paidAllowance`
     *
     * Requirements:
     *
     * - contract must be unpaused
     * - quantity must not be zero
     * - proof must be valid and correspond to `msg.sender`, `freeAllowance`, and `paidAllowance`
     * - contract mint phase must be `MintPhase.ALLOWLIST` or `MintPhase.WAITLIST`
     */
    function mint(
        uint256 quantity,
        uint256 freeAllowance,
        uint256 paidAllowance,
        bytes32[] calldata proof
    ) external payable;

    /**
     * @dev Returns allowlist and waitlist claims for `by` address.
     *
     * by - the address to retrieve claims for
     */
    function getClaimed(
        address by
    ) external view returns (uint16 allowClaims, uint16 waitClaims);

    /**
     * @dev Sets mint phase.
     *
     * mintPhase - the new mint phase to set
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     * - `mintPhase` must correspond to one of enum `MintPhase`
     */
    function setMintPhase(uint256 mintPhase) external;

    /**
     * @dev Sets mint phase beneficiary.
     *
     * beneficiary - the address to set as beneficiary
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     */
    function setBeneficiary(address payable beneficiary) external;

    /**
     * @dev Sets the token URI template.
     *
     * uriTemplate - the new URI template
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     */
    function setURITemplate(string[] memory uriTemplate) external;

    /**
     * @dev Returns contract URI for storefront-level metadata.
     */
    function contractURI() external view returns (string memory);

    /**
     * @dev Sets the contract URI.
     *
     * uri - the new URI
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     */
    function setContractURI(string memory uri) external;

    /**
     * @dev Sets the royalty receiver for ERC2981.
     *
     * receiver - the royalty receiver address
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     * - `receiver` cannot be the zero address
     */
    function setRoyaltyReceiver(address receiver) external;

    /**
     * @dev Returns the admin.
     */
    function admin() external view returns (address);

    /**
     * @dev Sets the admin address.
     *
     * admin - the new admin address
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     */
    function setAdmin(address admin) external;

    /**
     * @dev Initializes Rig pilots by creating the pilot sessions table.
     *
     * pilotsAddress - `ITablelandRigPilots` contract address
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     */
    function initPilots(address pilotsAddress) external;

    /**
     * @dev Returns the Tableland table name for the pilot sessions table.
     */
    function pilotSessionsTable() external view returns (string memory);

    /**
     * @dev Retrieves pilot info for a Rig.
     *
     * tokenId - the unique Rig token identifier
     *
     * Requirements:
     *
     * - `tokenId` must exist
     */
    function pilotInfo(
        uint256 tokenId
    ) external view returns (ITablelandRigPilots.PilotInfo memory);

    /**
     * @dev Retrieves pilot info for multiple Rigs.
     *
     * tokenIds - the unique Rig token identifiers
     *
     * Requirements:
     *
     * - `tokenIds` must exist
     */
    function pilotInfo(
        uint256[] calldata tokenIds
    ) external view returns (ITablelandRigPilots.PilotInfo[] memory);

    /**
     * @dev Trains a single Rig for a period of 30 days, putting it in-flight.
     *
     * tokenId - the unique Rig token identifier
     *
     * Requirements:
     *
     * - `tokenId` must exist
     * - pilot status must be valid (`UNTRAINED`)
     */
    function trainRig(uint256 tokenId) external;

    /**
     * @dev Puts multiple Rigs in training.
     *
     * tokenIds - the unique Rig token identifier
     *
     * Requirements:
     *
     * - Input array of `tokenIds` must be non-empty
     * - `msg.sender` must own the Rig
     * - There cannot exist a duplicate value in `tokenIds`
     * - Values are processed in order
     * - See `trainRig` for additional constraints on a per-token basis
     */
    function trainRig(uint256[] calldata tokenIds) external;

    /**
     * @dev Puts a single Rig in flight by setting a custom pilot.
     *
     * tokenId - the unique Rig token identifier
     * pilotContract - ERC-721 contract address of a desired Rig's pilot
     * pilotId - the unique token identifier at the target `pilotContract`
     *
     * Requirements:
     *
     * - `tokenId` must exist
     * - `msg.sender` must own the Rig
     * - Must be trained & flying with trainer, or already trained & parked
     * - `pilotContract` must be an ERC-721 contract *or* 0x0 to indicate a trainer pilot; cannot be the Rigs contract
     * - `pilotId` must be owned by `msg.sender` at `pilotContract` (does not apply to trainer pilots)
     * - Pilot can only be associated with one Rig at a time; parks the other Rig on conflict (does not apply to trainer pilots)
     */
    function pilotRig(
        uint256 tokenId,
        address pilotContract,
        uint256 pilotId
    ) external;

    /**
     * @dev Puts multiple Rigs in flight by setting a custom set of pilots.
     *
     * tokenIds - a list of unique Rig token identifiers
     * pilotContracts - a list of ERC-721 contract addresses of a desired Rig's pilot
     * pilotIds - a list of unique token identifiers at the target `pilotContract`
     *
     * Requirements:
     *
     * - All input parameters must be non-empty
     * - All input parameters must have an equal length
     * - There cannot exist a duplicate value in each of the individual parameters,
     *   except if using a trainer pilot (i.e., trainers aren't unique/owned NFTs).
     * - Values are processed in order (i.e., use same index for each array)
     * - See `pilotRig` for additional constraints on a per-token basis
     */
    function pilotRig(
        uint256[] calldata tokenIds,
        address[] calldata pilotContracts,
        uint256[] calldata pilotIds
    ) external;

    /**
     * @dev Parks a single Rig and ends the current pilot session.
     *
     * tokenId - the unique Rig token identifier
     *
     * Requirements:
     *
     * - `tokenId` must exist
     * - pilot status must be `TRAINING` or `PILOTED`
     * - pilot must have completed 30 days of training
     */
    function parkRig(uint256 tokenId) external;

    /**
     * @dev Parks multiple Rigs and ends the current pilot session.
     *
     * tokenIds - the unique Rig token identifiers
     *
     * Requirements:
     *
     * - Input array of `tokenIds` must be non-empty
     * - There cannot exist a duplicate value in `tokenIds`
     * - Values are processed in order
     * - See `parkRig` for additional constraints on a per-token basis
     */
    function parkRig(uint256[] calldata tokenIds) external;

    /**
     * @dev Allows contract owner to park any Rig that may be intentionally
     * causing buyers to lose gas on sales that can't complete while the
     * Rig is in-flight.
     *
     * tokenIds - the unique Rig token identifiers
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     */
    function parkRigAsOwner(uint256[] calldata tokenIds) external;

    /**
     * @dev Allows the admin to park any Rig that may be intentionally
     * causing buyers to lose gas on sales that can't complete while the
     * Rig is in-flight.
     *
     * tokenIds - the unique Rig token identifiers
     *
     * Requirements:
     *
     * - `msg.sender` must be the admin
     */
    function parkRigAsAdmin(uint256[] calldata tokenIds) external;

    /**
     * @dev Allows a token owner to transfer between accounts while in-flight
     * but blocks transfers by an approved address or operator.
     *
     * from - owner of `tokenId`
     * to - the address to transfer the token to
     * tokenId - the unique Rig token identifier
     *
     * Requirements:
     *
     * - Caller must own `tokenId` and *cannot* be an approved address or operator
     */
    function safeTransferWhileFlying(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Pauses minting.
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     * - contract must be unpaused
     */
    function pause() external;

    /**
     * @dev Unpauses minting.
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     * - contract must be paused
     */
    function unpause() external;
}