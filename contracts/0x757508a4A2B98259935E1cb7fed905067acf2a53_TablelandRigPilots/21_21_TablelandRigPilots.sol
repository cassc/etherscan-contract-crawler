// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.10 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@tableland/evm/contracts/utils/SQLHelpers.sol";
import "@tableland/evm/contracts/utils/TablelandDeployments.sol";
import "./ITablelandRigPilots.sol";

/**
 * @dev Implementation of {ITablelandRigPilots}.
 */
contract TablelandRigPilots is
    ITablelandRigPilots,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using ERC165CheckerUpgradeable for address;

    // Table prefix for the Rigs pilot sessions table.
    string private constant _PILOT_SESSIONS_PREFIX = "pilot_sessions";

    // Number of blocks that a Rig must train before piloting.
    uint256 private constant _PILOT_TRAINING_DURATION = 172800;

    // Mask of the lower 64 bits of a pilot; the flight start time
    uint256 private constant _BITMASK_START_TIME = (1 << 64) - 1;

    // Mask of all pilot bits, except the start time
    uint256 private constant _BITMASK_START_TIME_COMPLEMENT =
        _BITMASK_START_TIME ^ type(uint256).max;

    // Bit position of the pilot ID
    uint256 private constant _BITPOS_PILOT_ID = 64;

    // Bit position of the pilot contract
    uint256 private constant _BITPOS_PILOT_ADDR = 96;

    // Address of parent contract
    address private _parent;

    // Table ID for the Rigs pilot sessions table.
    uint256 private _pilotSessionsTableId;

    // Tracks the Rig `tokenId` to its current pilot, represented as a packed `uint256`.
    //
    // Bits layout:
    // - [0..63]    `startTime` - starting block number of pilot's flight time
    // - [64..95]   `pilotId` - ERC-721 token ID of the pilot at `pilotAddr`
    // - [96..255]  `pilotAddr` - address of the ERC-721 contract for the pilot
    mapping(uint16 => uint256) private _pilots;

    // Tracks the packed "pilot data" (pilot contract and pilot ID) to the Rig `tokenId`.
    // Used to help check if a custom pilot is in use.
    mapping(uint192 => uint16) private _pilotIndex;

    function initialize(address parent_) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        _parent = parent_;
        _pilotSessionsTableId = TablelandDeployments.get().createTable(
            address(this),
            SQLHelpers.toCreateFromSchema(
                "id integer primary key,"
                "rig_id integer not null,"
                "owner text not null,"
                "pilot_contract text,"
                "pilot_id integer,"
                "start_time integer not null,"
                "end_time integer",
                _PILOT_SESSIONS_PREFIX
            )
        );
    }

    /**
     * @dev Throws if called by any account other than the parent.
     */
    modifier onlyParent() {
        _checkParent();
        _;
    }

    /**
     * @dev Throws if the sender is not the parent.
     */
    function _checkParent() private view {
        require(parent() == _msgSender(), "Pilots: caller is not the parent");
    }

    // =============================
    //      ITABLELANDRIGPILOTS
    // =============================

    /**
     * @dev See {ITablelandRigPilots-parent}.
     */
    function parent() public view returns (address) {
        return _parent;
    }

    /**
     * @dev See {ITablelandRigPilots-pilotSessionsTable}.
     */
    function pilotSessionsTable() external view returns (string memory) {
        return
            SQLHelpers.toNameFromId(
                _PILOT_SESSIONS_PREFIX,
                _pilotSessionsTableId
            );
    }

    /**
     * @dev See {ITablelandRigPilots-pilotInfo}.
     */
    function pilotInfo(
        uint256 tokenId
    ) external view returns (PilotInfo memory) {
        return
            PilotInfo(
                _pilotStatus(tokenId),
                pilotStartTime(tokenId),
                _canPilot(tokenId),
                address(
                    uint160(_pilots[uint16(tokenId)] >> _BITPOS_PILOT_ADDR)
                ),
                uint256(uint32(_pilots[uint16(tokenId)] >> _BITPOS_PILOT_ID))
            );
    }

    /**
     * @dev See {ITablelandRigPilots-pilotStartTime}.
     */
    function pilotStartTime(uint256 tokenId) public view returns (uint64) {
        return uint64(_pilots[uint16(tokenId)]);
    }

    /**
     * @dev Returns a pilot's data (packed `uint32` pilot ID and `uint160` pilot contract).
     *
     * tokenId - the unique Rig token identifier
     */
    function _pilotData(uint256 tokenId) private view returns (uint192) {
        return uint192(_pilots[uint16(tokenId)] >> _BITPOS_PILOT_ID);
    }

    /**
     * @dev Sets a pilot's start time.
     *
     * tokenId - the unique Rig token identifier
     * startTime - the starting block number when putting a Rig into flight
     */
    function _setStartTime(uint16 tokenId, uint64 startTime) private {
        // Cast `startTime` with assembly to avoid redundant masking
        uint256 startTimeCasted;
        assembly {
            startTimeCasted := startTime
        }

        // Set the pilot, using the complement to mask all bits, except the start time
        // If the provided start time is zero, the mask already sets it to zero
        uint256 pilot = _pilots[tokenId];
        _pilots[tokenId] = startTimeCasted == 0
            ? pilot & _BITMASK_START_TIME_COMPLEMENT
            : (pilot & _BITMASK_START_TIME_COMPLEMENT) | startTimeCasted;
    }

    /**
     * @dev Sets the "pilot data" (both the pilot ID and pilot contract) for a pilot.
     *
     * tokenId - the unique Rig token identifier
     * pilotAddr - ERC-721 contract address of a desired Rig's pilot
     * pilotId - the unique token identifier at the target `pilotAddr`
     */
    function _setPilotData(
        uint16 tokenId,
        uint160 pilotAddr,
        uint32 pilotId
    ) private {
        // Cast "pilot data" (pilot contract and pilot ID) with assembly to avoid redundant masking
        uint256 pilot = _pilots[tokenId];
        uint256 pilotAddrCasted;
        uint256 pilotIdCasted;
        assembly {
            pilotAddrCasted := pilotAddr
            pilotIdCasted := pilotId
        }

        // Set the pilot by first masking the start time
        pilot =
            (pilot & _BITMASK_START_TIME) |
            (pilotIdCasted << _BITPOS_PILOT_ID) |
            (pilotAddrCasted << _BITPOS_PILOT_ADDR);
        _pilots[tokenId] = pilot;
    }

    /**
     * @dev Returns the current Garage status of a Rig.
     *
     * tokenId - the unique Rig token identifier
     */
    function _pilotStatus(uint256 tokenId) private view returns (GarageStatus) {
        // The `park` logic sets "pilot data" (pilot ID and pilot contract) to `0` if both of these are true:
        //   - Pilot data is currently `1` (contract is zero and trainer pilot is in use, `1`)
        //   - Rig has not been training for long enough
        // i.e., `park` results in a status of `UNTRAINED` or `PARKED`
        // Invariant: pilot data cannot be `0` if `startTime` is > `0`
        return
            pilotStartTime(tokenId) == 0
                ? (
                    _pilotData(tokenId) == 0
                        ? GarageStatus.UNTRAINED
                        : GarageStatus.PARKED
                )
                : (
                    _pilotData(tokenId) == 1
                        ? GarageStatus.TRAINING
                        : GarageStatus.PILOTED
                );
    }

    /**
     * @dev Returns whether or not a Rig can be piloted.
     *
     * tokenId - the unique Rig token identifier
     */
    function _canPilot(uint256 tokenId) private view returns (bool) {
        // Cannot switch real pilots mid-flight, but can go from trainer -> real pilot
        // There are two ways to pilot:
        //   1. In a `PARKED` status
        //   2. In a `TRAINING` status for long enough (30 days; 172800 blocks)
        GarageStatus status = _pilotStatus(tokenId);
        return
            status == GarageStatus.PARKED ||
            (status == GarageStatus.TRAINING &&
                block.number >=
                pilotStartTime(tokenId) + _PILOT_TRAINING_DURATION);
    }

    /**
     * @dev See {ITablelandRigPilots-trainRig}.
     */
    function trainRig(address sender, uint256 tokenId) external onlyParent {
        // Validate the Rig is untrained
        if (_pilotStatus(tokenId) != GarageStatus.UNTRAINED)
            revert InvalidPilotStatus();

        // Start training
        _setStartTime(uint16(tokenId), uint64(block.number));

        // Assign a trainer pilot to the Rig in `_pilots`
        // The "pilot data" is pilot contract `0` and pilot ID `1`
        _setPilotData(uint16(tokenId), 0, 1);

        // Insert the Rig training session into the Tableland pilot sessions table
        TablelandDeployments.get().runSQL(
            address(this),
            _pilotSessionsTableId,
            SQLHelpers.toInsert(
                _PILOT_SESSIONS_PREFIX,
                _pilotSessionsTableId,
                "rig_id,owner,start_time",
                string.concat(
                    StringsUpgradeable.toString(uint16(tokenId)),
                    ",",
                    SQLHelpers.quote(StringsUpgradeable.toHexString(sender)),
                    ",",
                    StringsUpgradeable.toString(uint64(block.number))
                )
            )
        );

        emit Training(tokenId);
    }

    /**
     * @dev See {ITablelandRigPilots-pilotRig}.
     */
    function pilotRig(
        address sender,
        uint256 tokenId,
        address pilotAddr,
        uint256 pilotId
    ) external onlyParent {
        // Verify the `pilotId` fits into a `uint32` (required for packing)
        if (pilotId > type(uint32).max)
            revert InvalidCustomPilot("pilot id too big");

        // Check if `pilotAddr` is an ERC-721; cannot be the Rigs contract
        if (
            pilotAddr == parent() ||
            !pilotAddr.supportsInterface(type(IERC721Upgradeable).interfaceId)
        ) revert InvalidCustomPilot("pilot contract not supported");

        // Check ownership of `pilotId` at target `pilotAddr`
        if (IERC721Upgradeable(pilotAddr).ownerOf(pilotId) != sender)
            revert InvalidCustomPilot("unauthorized");

        // Validate the Rig can be piloted
        if (!_canPilot(tokenId)) revert InvalidPilotStatus();

        // Initialize the packed "pilot data" (pilot ID `uint32` with a pilot contract `uint160`, shifted 32 bits)
        uint192 pilotData = (uint192(pilotId) |
            (uint192(uint160(pilotAddr)) << 32));

        // Verify if a pilot is already in use, by checking:
        // 1. Has the custom pilot been used before
        // 2. Was the pilot most recently used by a *different* Rig
        // 3. Is the other Rig in-flight (not `PARKED`)
        // If a different, in-flight Rig is using this pilot, park the other Rig
        if (
            _pilotIndex[pilotData] != 0 &&
            _pilotIndex[pilotData] != tokenId &&
            _pilotStatus(_pilotIndex[pilotData]) != GarageStatus.PARKED
        ) parkRig(_pilotIndex[pilotData], false);

        // If the Rig is training, end its training session (no parking required) to then open a new pilot session
        // Pilot has completed training at this point (training validation is checked above)
        if (_pilotStatus(tokenId) == GarageStatus.TRAINING) {
            // Update the pilot's existing training session with its `end_time`
            string memory setters = string.concat(
                "end_time=",
                StringsUpgradeable.toString(uint64(block.number))
            );
            // Only update the row with the matching `rig_id` and `start_time`
            string memory filters = string.concat(
                "rig_id=",
                StringsUpgradeable.toString(uint16(tokenId)),
                " and ",
                "start_time=",
                StringsUpgradeable.toString(pilotStartTime(tokenId))
            );
            TablelandDeployments.get().runSQL(
                address(this),
                _pilotSessionsTableId,
                SQLHelpers.toUpdate(
                    _PILOT_SESSIONS_PREFIX,
                    _pilotSessionsTableId,
                    setters,
                    filters
                )
            );
        }
        // The Rig is either `PARKED` or setting its first pilot while in a `TRAINED` status
        // Set the start time for the new pilot session
        _setStartTime(uint16(tokenId), uint64(block.number));

        // Insert the pilot into the Tableland pilot sessions table
        TablelandDeployments.get().runSQL(
            address(this),
            _pilotSessionsTableId,
            SQLHelpers.toInsert(
                _PILOT_SESSIONS_PREFIX,
                _pilotSessionsTableId,
                "rig_id,owner,pilot_contract,pilot_id,start_time",
                string.concat(
                    StringsUpgradeable.toString(uint16(tokenId)),
                    ",",
                    SQLHelpers.quote(StringsUpgradeable.toHexString(sender)),
                    ",",
                    SQLHelpers.quote(Strings.toHexString(pilotAddr)),
                    ",",
                    StringsUpgradeable.toString(uint32(pilotId)),
                    ",",
                    StringsUpgradeable.toString(uint64(block.number))
                )
            )
        );

        // Update the pilot data and index
        _setPilotData(uint16(tokenId), uint160(pilotAddr), uint32(pilotId));
        _pilotIndex[pilotData] = uint16(tokenId);

        emit Piloted(tokenId, pilotAddr, pilotId);
    }

    /**
     * @dev See {ITablelandRigPilots-parkRig}.
     */
    function parkRig(uint256 tokenId, bool force) public onlyParent {
        // Ensure Rig is currently in-flight
        GarageStatus status = _pilotStatus(tokenId);
        if (
            !(status == GarageStatus.TRAINING || status == GarageStatus.PILOTED)
        ) revert InvalidPilotStatus();
        // Session update type is dependent on training completion status
        // Use `setters` for setting SQL update values, and `startTime` is used for checking training completion status
        string memory setters;
        uint64 startTime = pilotStartTime(tokenId);
        bool trainingIncomplete = status == GarageStatus.TRAINING &&
            !(block.number >= startTime + _PILOT_TRAINING_DURATION);
        // Pilot training is incomplete; reset the training pilot such that the Rig must train again
        if (trainingIncomplete) _setPilotData(uint16(tokenId), 0, 0);
        // If the pilot is untrained or being force parked, there are zero flight time rewards
        if (trainingIncomplete || force) {
            // Update the row in pilot sessions table with its `end_time` equal to the `start_time`
            setters = string.concat(
                "end_time=",
                StringsUpgradeable.toString(startTime)
            );
        } else {
            // Training is complete, and the Rig is being parked without "malicious" force park origins
            // Update the row in the pilot sessions table with its `end_time` to accrue flight time rewards
            setters = string.concat(
                "end_time=",
                StringsUpgradeable.toString(uint64(block.number))
            );
        }

        // Only update the row with the matching `rig_id` and `start_time`
        string memory filters = string.concat(
            "rig_id=",
            StringsUpgradeable.toString(uint16(tokenId)),
            " and ",
            "start_time=",
            StringsUpgradeable.toString(startTime)
        );

        // Set the `startTime` to `0` to indicate the Rig is now parked
        _setStartTime(uint16(tokenId), 0);

        // Update the pilot information in the Tableland pilot sessions table
        TablelandDeployments.get().runSQL(
            address(this),
            _pilotSessionsTableId,
            SQLHelpers.toUpdate(
                _PILOT_SESSIONS_PREFIX,
                _pilotSessionsTableId,
                setters,
                filters
            )
        );

        emit Parked(tokenId);
    }

    /**
     * @dev See {ITablelandRigPilots-updateSessionOwner}.
     */
    function updateSessionOwner(
        uint256 tokenId,
        address newOwner
    ) external onlyParent {
        // Update the row in pilot sessions table with its new `owner`
        uint64 startTime = pilotStartTime(tokenId);
        string memory setters = string.concat(
            "owner=",
            SQLHelpers.quote(StringsUpgradeable.toHexString(newOwner))
        );
        // Only update the row with the matching `rig_id` and `start_time`
        string memory filters = string.concat(
            "rig_id=",
            StringsUpgradeable.toString(uint16(tokenId)),
            " and ",
            "start_time=",
            StringsUpgradeable.toString(startTime)
        );
        // Update the pilot information in the Tableland pilot sessions table
        TablelandDeployments.get().runSQL(
            address(this),
            _pilotSessionsTableId,
            SQLHelpers.toUpdate(
                _PILOT_SESSIONS_PREFIX,
                _pilotSessionsTableId,
                setters,
                filters
            )
        );
    }

    /**
     * @dev Required to create and receive an ERC-721 Tableland TABLE token for pilot sessions.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure returns (bytes4) {
        return 0x150b7a02;
    }

    // =============================
    //       UUPSUpgradeable
    // =============================

    /**
     * @dev See {UUPSUpgradeable-_authorizeUpgrade}.
     */
    function _authorizeUpgrade(address) internal view override onlyOwner {} // solhint-disable no-empty-blocks
}