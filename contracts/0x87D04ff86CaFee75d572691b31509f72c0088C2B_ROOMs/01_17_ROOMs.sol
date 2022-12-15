// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IFloorToken is IERC721 {
    function sizes(uint256 _tokenId) external view returns (uint16 size);
}

/// @custom:security-contact [email protected]
contract ROOMs is ERC721, ERC721URIStorage, ERC721Royalty, AccessControl {
    using Counters for Counters.Counter;

    string private _contractURIHash = "QmR2Mz8Bpztv8SHpzjnFrS4e6UutFn52C7G9FktMBfxXen";

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DESIGNER_ROLE = keccak256("DESIGNER_ROLE");
    Counters.Counter private _roomIdCounter;
    Counters.Counter private _raffleIdCounter;


    IFloorToken public FloorContract;

    struct ROOM {
        uint256 id;
        string title;
        string description;
        string architect;
        address architect_address;
        string image;
        string model;
        string series;
        uint16 slots;
        address creator;
        string metadataURI;
        bool cc0;
    }

    mapping(uint256 => ROOM) public roomById;
    mapping(uint256 => uint256) public tokenToRoom;

    struct Raffle {
        uint256 id;
        uint256 room;
        uint256[] allowedFloors;
        uint256 timeStart;
        uint256 timeEnd;
        Floor winner;
        Floor[] participants;
    }

    mapping(uint256 => bool) public designHasRaffle;

    struct Floor {
        uint256 id;
        address owner;
    }

    mapping(uint256 => Raffle) public raffleById;


    event NewDesign(ROOM room);
    event NewRaffle(Raffle raffle);
    event NewRaffleEntry(Raffle raffle, Floor floor);
    event RaffleClosed(Raffle raffle);
    event DesignUpdated(ROOM room);


    // goerli floor token: 0x22b512cC7916f8ed1033bb61a56c5a27078b963D
    constructor(address _floorToken) ERC721("MOCA ROOMs", "ROOM") {
        FloorContract = IFloorToken(_floorToken);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(DESIGNER_ROLE, msg.sender);
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked('ipfs://', _contractURIHash));
    }

    function setContractURIHash(string memory newContractURIHash) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _contractURIHash = newContractURIHash;
    }

    function updateDesign(uint256 _roomId, ROOM memory design) public onlyRole(DESIGNER_ROLE) {
        ROOM storage room = roomById[_roomId];
        require(room.creator == msg.sender, "You're not the creator of this ROOM Design.");

        room.title = design.title;
        room.description = design.description;
        room.architect = design.architect;
        room.architect_address = design.architect_address;
        room.image = design.image;
        room.model = design.model;
        room.series = design.series;
        room.slots = design.slots;
        room.metadataURI = design.metadataURI;
        room.cc0 = design.cc0;

        emit DesignUpdated(room);
    }

    function closeRoomRaffle(uint256 raffleId) public {
        Raffle storage raffle = raffleById[raffleId];
        require(raffle.winner.owner == address(0), "The winner has already been determined.");

        if (raffle.participants.length > 0) {

            uint256 winner_index;
            if (raffle.participants.length > 1) {
                winner_index = random(0, raffle.participants.length - 1);
            } else {
                winner_index = 0;
            }

            raffle.winner = raffle.participants[winner_index];

            for (uint256 i = 0; i < raffle.participants.length; i++) {
                // check winner and send back FLOORs
                if (raffle.participants[i].id == raffle.winner.id) continue;
                FloorContract.transferFrom(address(this), raffle.participants[i].owner, raffle.participants[i].id);
            }

            ROOM memory room = roomById[raffle.room];
            safeMint(raffle.winner.owner, raffle.winner.id, room.metadataURI, raffle.room);
            _setTokenRoyalty(raffle.winner.id, room.architect_address, 10000);
            FloorContract.transferFrom(address(this), address(0x000000000000000000000000000000000000dEaD), raffle.winner.id);

        } else {
            ROOM memory room = roomById[raffle.room];
            delete designHasRaffle[room.id];
        }

        emit RaffleClosed(raffle);
    }

    function enterRoomRaffle(uint256 raffleId, uint256 floorId) public {
        Raffle storage raffle = raffleById[raffleId];
        ROOM memory room = roomById[raffle.room];

        require(FloorContract.sizes(floorId) == room.slots, "Size of Floor does not match size of Room.");

        require(block.timestamp >= raffle.timeStart, "Raffle not started.");
        require(block.timestamp < raffle.timeEnd, "Raffle ended.");
        require(raffle.winner.owner == address(0), "Raffle closed.");

        bool allowed = false;
        if (raffle.allowedFloors.length > 0) {
            for (uint256 i = 0; i < raffle.allowedFloors.length; i++) {
                if (raffle.allowedFloors[i] == floorId) {
                    allowed = true;
                    break;
                }
            }
        } else {
            allowed = true;
        }

        require(allowed == true, "You're not allowed to join this raffle.");

        FloorContract.transferFrom(msg.sender, address(this), floorId);

        Floor memory floor;
        floor.id = floorId;
        floor.owner = msg.sender;

        raffle.participants.push(floor);

        emit NewRaffleEntry(raffle, floor);
    }

    function createRoomRaffle(uint256 roomId, uint256[] memory allowedFloors, uint256 timeStart, uint256 timeEnd) public onlyRole(DESIGNER_ROLE) {
        ROOM memory room = roomById[roomId];
        require(designHasRaffle[roomId] == false, "Raffle already started.");
        require(room.creator == msg.sender, "Only the creator can start a raffle for this room.");
        uint256 raffleId = _raffleIdCounter.current();
        _raffleIdCounter.increment();
        Raffle storage raffle = raffleById[raffleId];
        raffle.id = raffleId;
        raffle.room = roomId;
        raffle.allowedFloors = allowedFloors;
        raffle.timeStart = timeStart;
        raffle.timeEnd = timeEnd;

        designHasRaffle[roomId] = true;

        emit NewRaffle(raffle);
    }

    function createRoomDesign(ROOM memory design) public onlyRole(DESIGNER_ROLE) {
        uint256 roomId = _roomIdCounter.current();
        _roomIdCounter.increment();
        ROOM storage room = roomById[roomId];
        room.id = roomId;
        room.title = design.title;
        room.description = design.description;
        room.architect = design.architect;
        room.architect_address = design.architect_address;
        room.image = design.image;
        room.model = design.model;
        room.series = design.series;
        room.slots = design.slots;
        room.creator = msg.sender;
        room.metadataURI = design.metadataURI;
        room.cc0 = design.cc0;

        emit NewDesign(room);
    }

    function removeDesigner(address designer) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(DESIGNER_ROLE, designer);
    }

    function addDesigner(address designer) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(DESIGNER_ROLE, designer);
    }

    function safeMint(address to, uint256 tokenId, string memory uri, uint256 roomId) private {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        tokenToRoom[tokenId] = roomId;
    }

    function getRoomByTokenId(uint256 _tokenId) public view returns (ROOM memory room) {
        uint256 roomId = tokenToRoom[_tokenId];
        return roomById[roomId];
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage, ERC721Royalty) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, AccessControl, ERC721Royalty)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function random(uint256 min, uint256 max) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, blockhash(block.number - 1)))) % (max - min + 1) + min;
    }
}