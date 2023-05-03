// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.10 <0.9.0;

/**
 * @dev Interface of a TablelandRigPilots compliant contract.
 */
interface ITablelandRigPilots {
    // Thrown when attempting to interact with non-owned Rigs.
    error Unauthorized();

    // Thrown if a Pilot's contract is not ERC-721 compliant or pilot ID is greater than a uint32.
    error InvalidCustomPilot(string msg);

    // Thrown when a Garage action is attempted while a Rig is in a `GarageStatus` that is invalid for it to be performed.
    error InvalidPilotStatus();

    // Thrown upon a batch pilot update error.
    error InvalidBatchPilotAction();

    // Values describing a Rig's Garage status.
    enum GarageStatus {
        UNTRAINED,
        TRAINING,
        PARKED,
        PILOTED
    }

    // Pilot info for a Rig.
    struct PilotInfo {
        // The garage status of the Rig
        GarageStatus status;
        // Starting block number of pilot's flight time
        uint64 started;
        // Whether or not the Rig can be piloted
        bool pilotable;
        // Address of the ERC-721 contract for the pilot
        address addr;
        // ERC-721 token ID of the pilot at `address`
        uint256 id;
    }

    /**
     * @dev Emitted when a Rig starts its training.
     */
    event Training(uint256 tokenId);

    /**
     * @dev Emitted when a Rig is piloted.
     */
    event Piloted(uint256 tokenId, address pilotContract, uint256 pilotId);

    /**
     * @dev Emitted when a Rig is parked.
     */
    event Parked(uint256 tokenId);

    /**
     * @dev Returns the address of the contract parent parent.
     */
    function parent() external view returns (address);

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
    ) external view returns (PilotInfo memory);

    /**
     * @dev Returns a pilot's start time.
     *
     * tokenId - the unique Rig token identifier
     */
    function pilotStartTime(uint256 tokenId) external view returns (uint64);

    /**
     * @dev Trains a Rig for a period of 30 days, putting it in-flight.
     *
     * sender - the initiator address
     * tokenId - the unique Rig token identifier
     *
     * Requirements:
     *
     * - `sender` must own the Rig
     * - `tokenId` must exist
     * - pilot status must be valid (`UNTRAINED`)
     */
    function trainRig(address sender, uint256 tokenId) external;

    /**
     * @dev Puts a single Rig in flight with a "stock" trainer pilot.
     *
     * sender - the initiator address
     * tokenId - the unique Rig token identifier
     *
     * Requirements:
     *
     * - `tokenId` must exist
     * - `sender` must own the Rig
     * - Must already be trained & currently parked
     */
    function pilotRig(address sender, uint256 tokenId) external;

    /**
     * @dev Puts a single Rig in flight by setting a custom `Pilot`.
     *
     * sender - the initiator address
     * tokenId - the unique Rig token identifier
     * pilotContract - ERC-721 contract address of a desired Rig's pilot
     * pilotId - the unique token identifier at the target `pilotContract`
     *
     * Requirements:
     *
     * - `tokenId` must exist
     * - `sender` must own the Rig
     * - Ability to pilot must be `true` (trained & flying with trainer, or already trained & parked)
     * - `pilotContract` must be an ERC-721 contract; cannot be the Rigs contract
     * - `pilotId` must be owned by `msg.sender` at `pilotContract`
     * - `Pilot` can only be associated with one Rig at a time; parks the other Rig on conflict
     */
    function pilotRig(
        address sender,
        uint256 tokenId,
        address pilotContract,
        uint256 pilotId
    ) external;

    /**
     * @dev Parks a Rig and ends the current `Pilot` session.
     *
     * tokenId - the unique Rig token identifier
     * force - boolean to force park a Rig (contract owner only)
     *
     * Requirements:
     *
     * - `tokenId` must exist
     * - `sender` must own the Rig
     * - pilot status must be `TRAINING` or `PILOTED`
     * - pilot must have completed 30 days of training
     */
    function parkRig(uint256 tokenId, bool force) external;

    /**
     * @dev Updates the value of a pilot's `owner` in the current session, upon in-flight token transfers.
     *
     * tokenId - the unique Rig token identifier
     * newOwner - address of the new token owner
     *
     * Requirements:
     *
     * - A parent method should implement a check to verify a caller owns `tokenId`, then call `updateSessionOwner`
     */
    function updateSessionOwner(uint256 tokenId, address newOwner) external;
}