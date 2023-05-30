//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "base64-sol/base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

//////////////////////////////////////////////

//  888b     d888        d8888 8888888b.    //
//  8888b   d8888       d88888 888   Y88b   //
//  88888b.d88888      d88P888 888    888   //
//  888Y88888P888     d88P 888 888   d88P   //
//  888 Y888P 888    d88P  888 8888888P"    //
//  888  Y8P  888   d88P   888 888          //
//  888   "   888  d8888888888 888          //
//  888       888 d88P     888 888          //

//////////////////////////////////////////////

interface MapInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

/// @title A ERC721 contract to create random maps and waypoints
/// @author Sam Mason de Caires
/// @notice This contract is heavily inspired by Dom Hofmann's Loot Project and allows for the on chain creation of maps and there various waypoints along the journey.
contract MapRestored is ERC721Enumerable, ReentrancyGuard, Ownable {
    MapInterface immutable mapV1;

    constructor(MapInterface v1Address) ERC721("Maps Restored", "MAP") {
        mapV1 = v1Address;
    }

    /// @notice Stores the min and max range of how many waypoints there can be in a map
    uint256[2] private waypointRange = [4, 12];

    /// @notice All the various prefixes for the waypoint name
    string[] private prefixes = [
        "Dripping",
        "Holy",
        "Teller",
        "Atlas",
        "Fenners",
        "Bridger",
        "Oake",
        "Damned",
        "Acreage",
        "Fate",
        "Trinity",
        "Diamond",
        "Halo",
        "Lake",
        "Crater",
        "Grail",
        "Basin",
        "Hill",
        "Dry",
        "Dragon",
        "Cloud"
    ];

    /// @notice All the various locations for the waypoint name
    string[] private locations = [
        "Town",
        "Village",
        "Forest",
        "Woods",
        "Mountains",
        "City",
        "Farm",
        "Providence",
        "Castle",
        "Manor",
        "House",
        "Cave",
        "Island",
        "Hamlet",
        "Springs",
        "Fort",
        "Loch",
        "Bunker",
        "Hovel",
        "Hall",
        "Reservoir"
        "Stones",
        "Peaks",
        "Borough",
        "Lake",
        "Land",
        "Hill"
    ];

    /// @notice Pseudo random number generator based on input
    /// @dev Not really random
    /// @param input The seed value
    function _random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    /// @notice Gets a random value from a min and max range
    /// @dev a 2 value array the left is min and right is max
    /// @param tokenId a parameter just like in doxygen (must be followed by parameter name)
    /// @param rangeTuple a tuple with left value as min number and right as max
    function randomFromRange(uint256 tokenId, uint256[2] memory rangeTuple)
        internal
        pure
        returns (uint256)
    {
        uint256 rand = _random(
            string(abi.encodePacked(Strings.toString(tokenId)))
        );

        return (rand % (rangeTuple[1] - rangeTuple[0])) + rangeTuple[0];
    }

    /// @notice Generates a singular  random point either x or y
    /// @dev Will generate a random value for x and y coords with a max value of 128
    /// @param tokenId a unique number that acts as a seed
    /// @param xOrY used as a another factor to the seed
    /// @param waypointIndex the waypoint index, used a a seed factor
    function _getWaypointPoint(
        uint256 tokenId,
        string memory xOrY,
        uint256 waypointIndex
    ) internal pure returns (uint256) {
        uint256 rand = _random(
            string(
                abi.encodePacked(
                    xOrY,
                    Strings.toString(tokenId),
                    Strings.toString(waypointIndex)
                )
            )
        );

        return rand % 128;
    }

    /// @notice Constructs the tokenURI, separated out from the public function as its a big function.
    /// @dev Generates the json data URI and svg data URI that ends up sent when someone requests the tokenURI
    /// @param tokenId the tokenId
    function _constructTokenURI(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        uint256 waypointCount = getWaypointCount(tokenId);

        string memory mapName = string(
            abi.encodePacked("Map #", Strings.toString(tokenId))
        );

        string memory waypointNameSVGs;
        for (uint256 index = 0; index < waypointCount; index++) {
            string memory name = getWaypointName(tokenId, index);
            uint256 ySpace = 20 * (index + 1);
            waypointNameSVGs = string(
                abi.encodePacked(
                    '<text dominant-baseline="middle" text-anchor="middle" fill="white" x="50%" y="',
                    Strings.toString(ySpace),
                    'px">',
                    name,
                    "</text>",
                    waypointNameSVGs
                )
            );
        }

        string memory waypointPointsSVGs;
        for (uint256 index = 0; index < waypointCount; index++) {
            uint256[2] memory coord = getWaypointCoord(tokenId, index);
            waypointPointsSVGs = string(
                abi.encodePacked(
                    Strings.toString(coord[0]),
                    ",",
                    Strings.toString(coord[1]),
                    " ",
                    waypointPointsSVGs
                )
            );
        }

        uint256[2] memory startCoord = getWaypointCoord(tokenId, 0);
        string memory startJourneySVGMarker = string(
            abi.encodePacked(
                '<circle fill="white" cx="',
                Strings.toString(startCoord[0]),
                '" cy="',
                Strings.toString(startCoord[1]),
                '" r="2"/>'
            )
        );

        uint256[2] memory endCoord = getWaypointCoord(
            tokenId,
            waypointCount - 1
        );
        string memory endJourneySVGMarker = string(
            abi.encodePacked(
                '<circle fill="white" cx="',
                Strings.toString(endCoord[0]),
                '" cy="',
                Strings.toString(endCoord[1]),
                '" r="2"/>'
            )
        );

        bytes memory svg = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400" preserveAspectRatio="xMidYMid meet" style="font:14px serif"><rect width="400" height="400" fill="black" />',
            waypointNameSVGs,
            '<g transform="translate(133, 260)">',
            '<rect transform="translate(-3, -3)" width="134" height="134" fill="none" stroke="white" stroke-width="2"/>'
            '<polyline fill="none" stroke="white" points="',
            waypointPointsSVGs,
            '"/>',
            startJourneySVGMarker,
            endJourneySVGMarker,
            "</g>",
            "</svg>"
        );

        bytes memory image = abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(svg))
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                mapName,
                                '", "image":"',
                                image,
                                '", "description": "Maps are (pseudo) randomly generated place names of waypoints along a adventurers journey, complete with a map. All data is stored on chain. Use Maps however you want and pair with your favourite adventure Loot."}'
                            )
                        )
                    )
                )
            );
    }

    /// @notice Allows someone to get the single coordinate for a waypoint given the tokenId and waypoint index
    /// @param tokenId the token ID
    /// @param waypointIndex the waypoint index
    /// @return Array of x & y coord between 0 - 128

    function getWaypointCoord(uint256 tokenId, uint256 waypointIndex)
        public
        view
        returns (uint256[2] memory)
    {
        require(_exists(tokenId), "Token ID is invalid");
        uint256 waypointCount = getWaypointCount(tokenId);
        require(
            waypointIndex >= 0 && waypointIndex < waypointCount,
            "Waypoint Index is invalid"
        );

        uint256 x = _getWaypointPoint(tokenId, "X", waypointIndex);
        uint256 y = _getWaypointPoint(tokenId, "Y", waypointIndex);

        return [x, y];
    }

    /// @notice Gets the number of waypoints for a tokenId
    /// @param tokenId the token ID
    /// @return The number of waypoints
    function getWaypointCount(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token ID is invalid");
        return randomFromRange(tokenId, waypointRange);
    }

    /// @notice Gets all waypoints for a given token ID
    /// @param tokenId the token ID
    /// @return An array of coordinate arrays each contains an x & y coordinate
    function getWaypointCoords(uint256 tokenId)
        public
        view
        returns (uint256[2][] memory)
    {
        require(_exists(tokenId), "Token ID is invalid");
        uint256 waypointCount = getWaypointCount(tokenId);
        uint256[2][] memory arr = new uint256[2][](waypointCount);

        for (uint256 index = 0; index < waypointCount; index++) {
            arr[index] = getWaypointCoord(tokenId, index);
        }

        return arr;
    }

    /// @notice Gets a single waypoint name given the tokenId and waypoint index
    /// @param tokenId the token ID
    /// @param waypointIndex the waypoint index
    /// @return A string of the name of the entity found at that waypoint
    function getWaypointName(uint256 tokenId, uint256 waypointIndex)
        public
        view
        returns (string memory)
    {
        require(_exists(tokenId), "Token ID is invalid");
        uint256 waypointCount = getWaypointCount(tokenId);
        require(
            waypointIndex >= 0 && waypointIndex < waypointCount,
            "Waypoint Index is invalid"
        );

        uint256 rand = _random(
            string(
                abi.encodePacked(
                    Strings.toString(tokenId),
                    Strings.toString(waypointIndex)
                )
            )
        );

        string memory output;
        string[2] memory waypointName;
        uint256 age = rand % 32;
        waypointName[0] = prefixes[rand % prefixes.length];
        waypointName[1] = locations[rand % locations.length];
        output = string(
            abi.encodePacked(waypointName[0], " ", waypointName[1], output)
        );

        if (age == 13) {
            output = string(abi.encodePacked("Mystic ", output));
        }

        if (age > 1 && age <= 4) {
            output = string(abi.encodePacked("Old ", output));
        }

        if (age >= 27) {
            output = string(abi.encodePacked("New ", output));
        }

        return output;
    }

    /// @notice Gets all waypoint names for a token ID
    /// @param tokenId the token ID
    /// @return An array of names of the entities found on this map
    function getWaypointNames(uint256 tokenId)
        public
        view
        returns (string[] memory)
    {
        require(_exists(tokenId), "Token ID is invalid");

        uint256 waypointCount = getWaypointCount(tokenId);
        string[] memory arr = new string[](waypointCount);
        for (uint256 index = 0; index < waypointCount; index++) {
            string memory name = getWaypointName(tokenId, index);
            arr[index] = name;
        }

        return arr;
    }

    /// @notice This "burns" the original map token and remints on the new token with fixed metadata
    /// @dev This will revert if tokenId's are incorrect
    /// @param tokenIds an array of token ids that are owned by the sender
    function claimRestoredMap(uint256[] memory tokenIds) public nonReentrant {
        for (uint256 index = 0; index < tokenIds.length; index++) {
            uint256 tokenIdForTransfer = tokenIds[index];
            require(
                mapV1.ownerOf(tokenIdForTransfer) == _msgSender(),
                "Sender does not own 1 or more Token Ids provided"
            );
            mapV1.transferFrom(_msgSender(), address(this), tokenIdForTransfer);
            _safeMint(_msgSender(), tokenIdForTransfer);
        }
    }

    /// @notice Allows the owner to find a map (mints a token)
    /// @param tokenId the token ID
    function ownerDiscoverMap(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId >= 9751 && tokenId < 10001, "Token ID invalid");
        _safeMint(owner(), tokenId);
    }

    /// @notice Returns the json data associated with this token ID
    /// @param tokenId the token ID
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(_constructTokenURI(tokenId));
    }
}