// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";

contract Metadata is Ownable {
    using Strings for uint256;

    struct Trait {
        string name;
        string image;
    }

    string[4] categoryNames = ["Color", "Expression", "Accesory", "Hat"];

    mapping(uint8=>mapping(uint8=>Trait)) public traitData;

    constructor() {}

    function uploadTraits(uint8 category, Trait[] calldata traits)
        public
        onlyOwner
    {
        require(traits.length == 16, "Wrong length");
        for (uint8 i = 0; i < traits.length; i++) {
            traitData[category][i] = Trait(traits[i].name, traits[i].image);
        }
    }

    function drawTrait(Trait memory trait)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<image x="0" y="0" width="64" height="64" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    trait.image,
                    '"/>'
                )
            );
    }

    function drawSVG(bool isFox, uint8[] memory traits)
        public
        view
        returns (string memory)
    {
        uint8 offset = isFox ? 4 : 0;
        string memory svgString = string(
            abi.encodePacked(
                drawTrait(traitData[offset][traits[0]]),
                drawTrait(traitData[1 + offset][traits[1]]),
                drawTrait(traitData[2 + offset][traits[2]]),
                drawTrait(traitData[3 + offset][traits[3]])
            )
        );

        return
            string(
                abi.encodePacked(
                    '<svg id="foxhen" width="100%" height="100%" version="1.1" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    svgString,
                    "</svg>"
                )
            );
    }

    function attributeForTypeAndValue(
        string memory categoryName,
        string memory value
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"',
                    categoryName,
                    '","value":"',
                    value,
                    '"}'
                )
            );
    }

    function compileAttributes(
        bool isFox,
        uint8[] memory traits,
        uint256 tokenId
    ) public view returns (string memory) {
        uint8 offset = isFox ? 4 : 0;
        string memory attributes = string(
            abi.encodePacked(
                attributeForTypeAndValue(
                    categoryNames[0],
                    traitData[offset][traits[0]].name
                ),
                ",",
                attributeForTypeAndValue(
                    categoryNames[1],
                    traitData[offset + 1][traits[1]].name
                ),
                ",",
                attributeForTypeAndValue(
                    categoryNames[2],
                    traitData[offset + 2][traits[2]].name
                ),
                ",",
                attributeForTypeAndValue(
                    categoryNames[3],
                    traitData[offset + 3][traits[3]].name
                ),
                ","
            )
        );
        return
            string(
                abi.encodePacked(
                    "[",
                    attributes,
                    '{"trait_type":"Generation","value":',
                    tokenId <= 10000 ? '"Gen 0"' : '"Gen 1"',
                    '},{"trait_type":"Type","value":',
                    isFox ? '"Fox"' : '"Hen"',
                    "}]"
                )
            );
    }

    function tokenMetadata(
        bool isFox,
        uint256 traitId,
        uint256 tokenId
    ) public view returns (string memory) {
        uint8[] memory traits = new uint8[](4);
        uint256 traitIdBackUp = traitId;
        for (uint8 i = 0; i < 4; i++) {
            uint8 exp = 3 - i;
            uint8 tmp = uint8(traitIdBackUp / (16**exp));
            traits[i] = tmp;
            traitIdBackUp -= tmp * 16**exp;
        }

        string memory svg = drawSVG(isFox, traits);

        string memory metadata = string(
            abi.encodePacked(
                '{"name": "',
                isFox ? "Fox #" : "Hen #",
                tokenId.toString(),
                '", "description": "A sunny day in the Summer begins, with the Farmlands and the Forest In its splendor, it seems like a normal day. But the cunning planning of the Foxes has begun, they know that the hens will do everything to protect their precious $EGG but can they keep them all without risk of losing them? A Risk-Reward economic game, where every action matters. No IPFS. No API. All stored and generated 100% on-chain", "image": "data:image/svg+xml;base64,',
                base64(bytes(svg)),
                '", "attributes":',
                compileAttributes(isFox, traits, tokenId),
                "}"
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    base64(bytes(metadata))
                )
            );
    }

    /** BASE 64 - Written by Brech Devos */

    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}