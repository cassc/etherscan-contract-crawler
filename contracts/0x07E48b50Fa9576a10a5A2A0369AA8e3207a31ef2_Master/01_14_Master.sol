// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Master is AccessControl, ReentrancyGuard, Pausable {
    bytes32 public constant ROLE_RANDOMIZER = keccak256("ROLE_RANDOMIZER");
    bytes32 public constant ROLE_PAUSER = keccak256("ROLE_PAUSER");
    bytes32 public constant ROLE_MANAGER = keccak256("ROLE_MANAGER");

    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Room {
        bytes32 id;
        bytes32 network;
        uint32 chainID;
        address creator;
        uint256 betLimitPerDay;
        uint256 maxBetPerPlayer;
        uint32 apiPermission;
    }
    mapping(uint256 => bytes32) private roomsIndex;
    mapping(bytes32 => Room) private rooms;
    uint256 _totalRoom;

    /// @notice Emitted when reserves is deposited.
    event RoomUpdated(
        bytes32 indexed roomId,
        address indexed contractAddress,
        uint256 betLimitPerDay,
        uint256 maxBetPerPlayer,
        uint32 apiPermission
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ROLE_PAUSER, msg.sender);
        _setupRole(ROLE_MANAGER, msg.sender);
        _totalRoom = 0;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ADMIN_PERMISSION_DENIED"
        );
        _;
    }

    modifier onlyRoomManager() {
        require(hasRole(ROLE_MANAGER, msg.sender), "MANAGER_PERMISSION_DENIED");
        _;
    }

    function addManager(address _addressToWhitelist) public onlyAdmin {
        _setupRole(ROLE_MANAGER, _addressToWhitelist);
    }

    function createRoom(
        bytes32 roomId,
        address creator,
        bytes32 network,
        uint32 chainID
    ) external nonReentrant whenNotPaused {
        Room storage room = rooms[roomId];
        require(room.id == 0, "ROOM_ALREADY_EXISTS");
        room.id = roomId;
        room.creator = creator;
        room.network = network;
        room.chainID = chainID;
        room.betLimitPerDay = 0;
        room.maxBetPerPlayer = 0;
        room.apiPermission = 0;
        roomsIndex[_totalRoom] = roomId;
        _totalRoom++;
    }

    /// @notice setting the room limit. Only available to room managers.
    function setRoomLimit(
        uint256 betLimitPerDay,
        uint256 maxBetPerPlayer,
        uint32 apiPermission,
        bytes32 roomId
    ) external nonReentrant whenNotPaused onlyRoomManager {
        require(rooms[roomId].creator != address(0), "ROOM_NOT_EXISTS");

        rooms[roomId].betLimitPerDay = betLimitPerDay;
        rooms[roomId].maxBetPerPlayer = maxBetPerPlayer;
        rooms[roomId].apiPermission = apiPermission;

        emit RoomUpdated(
            roomId,
            msg.sender,
            betLimitPerDay,
            maxBetPerPlayer,
            apiPermission
        );
    }

    function getTotalRoom() public view returns (uint256) {
        return _totalRoom;
    }

    function getRoomByIndex(uint256 index) public view returns (Room memory) {
        return rooms[roomsIndex[index]];
    }

    function getRoom(bytes32 roomId) public view returns (Room memory) {
        return rooms[roomId];
    }

    function getRoomList() public view returns (Room[] memory) {
        Room[] memory roomsArr = new Room[](_totalRoom);
        for (uint256 i = 0; i < _totalRoom; i++) {
            roomsArr[i] = rooms[roomsIndex[i]];
        }
        return roomsArr;
    }

    function pause() external whenNotPaused onlyAdmin {
        _pause();
    }

    function unpause() external whenPaused onlyAdmin {
        _unpause();
    }
}