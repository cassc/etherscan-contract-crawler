// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./interfaces/IBlockverseMetadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

struct BlockverseToken {
    IBlockverse.BlockverseFaction faction;
    uint8 bottom;
    uint8 eye;
    uint8 mouth;
    uint8 top;
}

contract BlockverseMetadata is IBlockverseMetadata, Ownable {
    using Strings for uint256;
    using Strings for uint8;

    string public cdnUrl;
    uint256[] public tidBreakpoints;
    uint256[] public seedBreakpoints;
    mapping(uint256 => uint8[]) public traitProbabilities;
    mapping(uint256 => uint8[]) public traitAliases;
    mapping(uint256 => mapping(uint8 => string)) public traitNames;

    function tokenURI(uint256 tokenId, IBlockverse.BlockverseFaction faction) external view override returns (string memory) {
        BlockverseToken memory tokenStruct = getTokenMetadata(tokenId, faction);

        string memory metadata;
        if (tokenStruct.faction == IBlockverse.BlockverseFaction.UNASSIGNED) {
            metadata = string(abi.encodePacked(
                '{',
                    '"name":"Blockverse #???",',
                    '"description":"",',
                    '"image":"', cdnUrl, '/unknown",',
                    '"attributes":[',
                        attributeForTypeAndValue("Faction", "???"),',',
                        attributeForTypeAndValue("Bottom", "???"),',',
                        attributeForTypeAndValue("Eye", "???"),',',
                        attributeForTypeAndValue("Mouth", "???"),',',
                        attributeForTypeAndValue("Top", "???"),
                    ']',
                "}"
            ));
        } else {
            string memory queryParams = string(abi.encodePacked(
                    "?base=",uint256(faction).toString(),
                    "&bottoms=",tokenStruct.bottom.toString(),
                    "&eyes=",tokenStruct.eye.toString(),
                    "&mouths=",tokenStruct.mouth.toString(),
                    "&tops=",tokenStruct.top.toString()
                ));
            metadata = string(abi.encodePacked(
                '{',
                    '"name":"Blockverse #',tokenId.toString(),'",',
                    '"description":"",',
                    '"image":"', cdnUrl, '/token',queryParams,'",',
                    '"skinImage":"', cdnUrl, '/skin',queryParams,'",',
                    '"attributes":[',
                        attributeForTypeAndValue("Faction", factionToString(faction)),',',
                        attributeForTypeAndValue("Bottom", traitNames[0][tokenStruct.bottom]),',',
                        attributeForTypeAndValue("Eye", traitNames[1][tokenStruct.eye]),',',
                        attributeForTypeAndValue("Mouth", traitNames[2][tokenStruct.mouth]),',',
                        attributeForTypeAndValue("Top", traitNames[3][tokenStruct.top]),
                    ']',
                "}"
            ));
        }

        return string(abi.encodePacked(
            "data:application/json;base64,",
            base64(bytes(metadata))
        ));
    }

    // METADATA/SEEDING
    function getTokenMetadata(uint256 tid, IBlockverse.BlockverseFaction faction) internal view returns (BlockverseToken memory tokenMetadata) {
        uint256 seed = getTokenSeed(tid);

        if (seed == 0) {
            tokenMetadata.faction = IBlockverse.BlockverseFaction.UNASSIGNED;
        } else {
            tokenMetadata.faction = faction;
            tokenMetadata.bottom = getTraitValue(seed, 0);
            tokenMetadata.eye = getTraitValue(seed, 1);
            tokenMetadata.mouth = getTraitValue(seed, 2);
            tokenMetadata.top = getTraitValue(seed, 3);
        }
    }

    function getTraitValue(uint256 seed, uint256 trait) public view returns (uint8 traitValue) {
        uint8 n = uint8(traitProbabilities[trait].length);

        uint16 traitSeed = uint16(seed >> trait * 16);
        traitValue = uint8(traitSeed) % n;
        uint8 rand = uint8(traitSeed >> 8);

        if (traitProbabilities[trait][traitValue] < rand) {
            traitValue = traitAliases[trait][traitValue];
        }
    }

    function getTokenSeed(uint256 tid) public view returns (uint256 seed) {
        require(tidBreakpoints.length == seedBreakpoints.length, "Invalid state");

        uint256 rangeSeed = 0;
        for (uint256 i; i < tidBreakpoints.length; i++) {
            if (tidBreakpoints[i] > tid) {
                rangeSeed = seedBreakpoints[i];
            }
        }

        seed = rangeSeed == 0 ? 0 : uint256(keccak256(abi.encodePacked(tid, rangeSeed)));
    }

    function addBreakpoint(uint256 seed, uint256 tid) external onlyOwner {
        require(seed != 0, "Seed can't be 0");
        require(tid != 0, "Token ID can't be 0");

        seedBreakpoints.push(seed);
        tidBreakpoints.push(tid);
    }

    // TRAIT UPLOAD
    function uploadTraitNames(uint8 traitType, uint8[] calldata traitIds, string[] calldata newTraitNames) external onlyOwner {
        require(traitIds.length == newTraitNames.length, "Mismatched inputs");
        for (uint i = 0; i < traitIds.length; i++) {
            traitNames[traitType][traitIds[i]] = newTraitNames[i];
        }
    }

    function uploadTraitProbabilities(uint8 traitType, uint8[] calldata newTraitProbabilities) external onlyOwner {
        delete traitProbabilities[traitType];
        for (uint i = 0; i < newTraitProbabilities.length; i++) {
            traitProbabilities[traitType].push(newTraitProbabilities[i]);
        }
    }

    function uploadTraitAliases(uint8 traitType, uint8[] calldata newTraitAliases) external onlyOwner {
        delete traitAliases[traitType];
        for (uint i = 0; i < newTraitAliases.length; i++) {
            traitAliases[traitType].push(newTraitAliases[i]);
        }
    }

    function setCdnUri(string memory newCdnUri) external onlyOwner {
        cdnUrl = newCdnUri;
    }

    // JSON Representation
    function factionToString(IBlockverse.BlockverseFaction faction) internal pure returns (string memory factionString) {
        factionString = "???";
        if (faction == IBlockverse.BlockverseFaction.APES) {
            factionString = "Apes";
        } else if (faction == IBlockverse.BlockverseFaction.KONGS) {
            factionString = "Kongs";
        } else if (faction == IBlockverse.BlockverseFaction.DOODLERS) {
            factionString = "Doodlers";
        } else if (faction == IBlockverse.BlockverseFaction.CATS) {
            factionString = "Cats";
        } else if (faction == IBlockverse.BlockverseFaction.KAIJUS) {
            factionString = "Kaijus";
        } else if (faction == IBlockverse.BlockverseFaction.ALIENS) {
            factionString = "Aliens";
        }
    }

    function attributeForTypeAndValue(string memory traitType, string memory value) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            traitType,
            '","value":"',
            value,
            '"}'
        ));
    }

    /** BASE 64 - Written by Brech Devos */
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
}