// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// @author: doorman                                                                                                                                                                                                                  

contract TheLabyrinth is ERC721, ReentrancyGuard, Ownable {

    event TokenMinted(address indexed _from, uint256 indexed _tokenId);
    event TokenBurned(address indexed _from, uint256 indexed _tokenId);

    string private _customBaseURI;
    string private _suffixURI;
    bool public paused = true;
    uint public claimPeriodEnd = 1640995199;
    uint256[] private maxSupplyByType = [1500, 1200, 900, 600, 200];
    address private stringifyDoorContractAddress = 0xf4794aEB9D243c024cf59B85b30ed94F5014168a;

    mapping(uint256 => uint256) private usedDoors;
    mapping(uint256 => uint256) private whiteDoors;

    using Counters for Counters.Counter;
    Counters.Counter private _whiteTriangleSupply;
    Counters.Counter private _whiteHexagonSupply;
    Counters.Counter private _whiteOctagonSupply;
    Counters.Counter private _whiteDecagonSupply;
    Counters.Counter private _whiteDodecagonSupply;

    Counters.Counter private _blackTriangleSupply;
    Counters.Counter private _blackHexagonSupply;
    Counters.Counter private _blackOctagonSupply;
    Counters.Counter private _blackDecagonSupply;
    Counters.Counter private _blackDodecagonSupply;

    Counters.Counter private _triangleClaimed;
    Counters.Counter private _hexagonClaimed;
    Counters.Counter private _octagonClaimed;
    Counters.Counter private _decagonClaimed;
    Counters.Counter private _dodecagonClaimed;

    Counters.Counter public totalSupply;
    Counters.Counter public whiteMazesSupply;
    Counters.Counter public blackMazesSupply;
    Counters.Counter public claimed;
    Counters.Counter public burned;

    function claim(uint256[] memory doors, uint256[5] memory tokenTypes) public nonReentrant  {
        require(!paused, "The mint is not active at the moment.");
        require(doors.length > 0, "No doors provided.");
        require(block.timestamp < claimPeriodEnd, "The claim period ended.");

        uint256 doorPointsNeeded = tokenTypes[0] + tokenTypes[1] * 2 + tokenTypes[2] * 3 + tokenTypes[3] * 4 + tokenTypes[4] * 5;

        require(doorPointsNeeded > 0, "No token types provided.");
        require((_triangleClaimed.current() + tokenTypes[0]) <= maxSupplyByType[0], "The mint would exceed max supply of triangles.");
        require((_hexagonClaimed.current() + tokenTypes[1]) <= maxSupplyByType[1], "The mint would exceed max supply of hexagons.");
        require((_octagonClaimed.current() + tokenTypes[2]) <= maxSupplyByType[2], "The mint would exceed max supply of octagons.");
        require((_decagonClaimed.current() + tokenTypes[3]) <= maxSupplyByType[3], "The mint would exceed max supply of decagons.");
        require((_dodecagonClaimed.current() + tokenTypes[4]) <= maxSupplyByType[4], "The mint would exceed max supply of dodecagons.");

        uint256 doorPoints = 0;

        /*  Check if no duplicated doors
            Check ownership of doors
            Check if all doors unused */
        for (uint i = 0; i < doors.length; i++) {
            require(ERC721(stringifyDoorContractAddress).ownerOf(doors[i]) == _msgSender(), "You are not the owner of at least one door.");
            require(usedDoors[doors[i]] == 0, "At least one door has already been used to claim.");
            for (uint j = i + 1; j < doors.length; j++) {
                require(doors[i] != doors[j], "Duplicated doors detected.");
            }
            // Calculate door points
            if (whiteDoors[doors[i]] == 1) {
                doorPoints += 5;
            } else {
                doorPoints++;
            }
        }

        // Check if user have enough door points to claim
        require(doorPoints >= doorPointsNeeded, "You don't have enough door points to claim these mazes.");

        // Mint triangles
        for (uint i = 0; i < tokenTypes[0]; i++) {
            _whiteTriangleSupply.increment();
            _triangleClaimed.increment();
            totalSupply.increment();
            whiteMazesSupply.increment();
            claimed.increment();

            _safeMint(_msgSender(),  _triangleClaimed.current());
            emit TokenMinted(_msgSender(), _triangleClaimed.current());
        }

        // Mint hexagons
        for (uint i = 0; i < tokenTypes[1]; i++) {
            _whiteHexagonSupply.increment();
            _hexagonClaimed.increment();
            totalSupply.increment();
            whiteMazesSupply.increment();
            claimed.increment();

            _safeMint(_msgSender(),  1500 + _hexagonClaimed.current());
            emit TokenMinted(_msgSender(), 1500 + _hexagonClaimed.current());
        }

        // Mint octagons
        for (uint i = 0; i < tokenTypes[2]; i++) {
            _whiteOctagonSupply.increment();
            _octagonClaimed.increment();
            totalSupply.increment();
            whiteMazesSupply.increment();
            claimed.increment();

            _safeMint(_msgSender(),  2700 + _octagonClaimed.current());
            emit TokenMinted(_msgSender(), 2700 + _octagonClaimed.current());
        }

        // Mint decagons
        for (uint i = 0; i < tokenTypes[3]; i++) {
            _whiteDecagonSupply.increment();
            _decagonClaimed.increment();
            totalSupply.increment();
            whiteMazesSupply.increment();
            claimed.increment();

            _safeMint(_msgSender(),  3600 + _decagonClaimed.current());
            emit TokenMinted(_msgSender(), 3600 + _decagonClaimed.current());
        }

        // Mint dodecagons
        for (uint i = 0; i < tokenTypes[4]; i++) {
            _whiteDodecagonSupply.increment();
            _dodecagonClaimed.increment();
            totalSupply.increment();
            whiteMazesSupply.increment();
            claimed.increment();

            _safeMint(_msgSender(),  4200 + _dodecagonClaimed.current());
            emit TokenMinted(_msgSender(), 4200 + _dodecagonClaimed.current());
        }

        // Mark doors as used
        for (uint i = 0; i < doors.length; i++) {
            usedDoors[doors[i]] = 1;
        }
    }

    // Burn: takes to maze ids, burns them and mints the firstMazeId in black
    function burn(uint256 firstMazeId, uint256 secondMazeId) public nonReentrant  {
        require(firstMazeId != secondMazeId, "Maze ids should be different.");
        require((firstMazeId > 0 && firstMazeId <= 4400) && (secondMazeId > 0 && secondMazeId <= 4400), "Invalid maze ids. You can only burn white mazes.");
        require(_exists(firstMazeId) && _exists(secondMazeId), "At least one of mazes does not exist (not minted or already burned).");
        require((ownerOf(firstMazeId) == _msgSender()) && (ownerOf(secondMazeId) == _msgSender()), "You should own mazes to burn them.");

        _burn(firstMazeId);
        _burn(secondMazeId);
        _safeMint(_msgSender(),  4400 + firstMazeId);

        emit TokenBurned(_msgSender(), firstMazeId);
        emit TokenBurned(_msgSender(), secondMazeId);
        emit TokenMinted(_msgSender(), 4400 + firstMazeId);

        whiteMazesSupply.decrement();
        whiteMazesSupply.decrement();
        blackMazesSupply.increment();
        totalSupply.decrement();
        burned.increment();
        burned.increment();

        if (secondMazeId < 1501) {
            _whiteTriangleSupply.decrement();
        } else if (secondMazeId > 1500 && secondMazeId <= 2700) {
            _whiteHexagonSupply.decrement();
        } else if (secondMazeId > 2700 && secondMazeId <= 3600) {
            _whiteOctagonSupply.decrement();
        } else if (secondMazeId > 3600 && secondMazeId <= 4200) {
            _whiteDecagonSupply.decrement();
        } else {
            _whiteDodecagonSupply.decrement();
        }

        if (firstMazeId < 1501) {
            _blackTriangleSupply.increment();
        } else if (firstMazeId > 1500 && firstMazeId <= 2700) {
            _blackHexagonSupply.increment();
        } else if (firstMazeId > 2700 && firstMazeId <= 3600) {
            _blackOctagonSupply.increment();
        } else if (firstMazeId > 3600 && firstMazeId <= 4200) {
            _blackDecagonSupply.increment();
        } else {
            _blackDodecagonSupply.increment();
        }
    }

    function isDoorValid(uint256 doorId) public view returns (bool) {
        return usedDoors[doorId] == 0;
    }

    // If the door is not valid, the index of this door id in the returned array will contain 0
    function getValidDoors(uint256[] memory doorIds) public view returns (uint256[] memory) {
        for (uint i = 0; i < doorIds.length; i++) {
            if (usedDoors[doorIds[i]] == 1) {
                doorIds[i] = 0;
            }
        }
        return doorIds;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_customBaseURI, toString(tokenId), _suffixURI));
    }

    function getWhiteSupplyPerType() public view returns (uint256[5] memory) {
        return [_whiteTriangleSupply.current(), _whiteHexagonSupply.current(), _whiteOctagonSupply.current(), _whiteDecagonSupply.current(), _whiteDodecagonSupply.current()];
    }

    function getBlackSupplyPerType() public view returns (uint256[5] memory) {
        return [_blackTriangleSupply.current(), _blackHexagonSupply.current(), _blackOctagonSupply.current(), _blackDecagonSupply.current(), _blackDodecagonSupply.current()];
    }

    function getSupplyPerType() public view returns (uint256[5] memory) {
        return [
            _whiteTriangleSupply.current() + _blackTriangleSupply.current(), 
            _whiteHexagonSupply.current() + _blackHexagonSupply.current(), 
            _whiteOctagonSupply.current() + _blackOctagonSupply.current(), 
            _whiteDecagonSupply.current() + _blackDecagonSupply.current(), 
            _whiteDodecagonSupply.current() + _blackDodecagonSupply.current()
        ];
    }

    function getClaimedPerType() public view returns (uint256[5] memory) {
        return [_triangleClaimed.current(), _hexagonClaimed.current(), _octagonClaimed.current(), _decagonClaimed.current(), _dodecagonClaimed.current()];
    }

    function flipMintState() public onlyOwner {
        paused = !paused;
    }

    function updateCustomBaseURI(string memory customBaseURI) public onlyOwner {
        _customBaseURI = customBaseURI;
    }

    function updateSuffixURI(string memory suffixURI) public onlyOwner {
        _suffixURI = suffixURI;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    constructor(string memory customBaseURI, string memory suffixURI, uint16[] memory whiteIds) ERC721("The Labyrinth", "MAZE") Ownable() {
        _customBaseURI = customBaseURI;
        _suffixURI = suffixURI;
        
        for (uint i = 0; i < whiteIds.length; i++) {
            whiteDoors[whiteIds[i]] = 1;
        }
    }
}