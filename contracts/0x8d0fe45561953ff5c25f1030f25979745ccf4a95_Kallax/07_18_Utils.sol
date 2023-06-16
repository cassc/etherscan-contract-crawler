// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17.0;

/// @title Utils
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
/// @notice Utility functions for constructing on-chain Kallax NFT
library Utils {
    struct UnpackedToken {
        uint16 tokenArt;
        uint256 density;
        uint256 depth;
        uint256 facing;
        uint256 tileDivision;
        uint256 segmentSize;
        uint256 palette;
    }

    string internal constant BASE64_TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function htmlToURI(string memory _source) internal pure returns (string memory) {
        return string.concat("data:text/html;base64,", encodeBase64(bytes(_source)));
    }

    function formatTokenURI(
        string memory _imageURI,
        string memory _animationURI,
        string memory _name,
        string memory _description,
        string memory _properties
    )
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            "data:application/json;base64,",
            encodeBase64(
                bytes(
                    string.concat(
                        '{"name":"',
                        _name,
                        '","description":"',
                        _description,
                        '","attributes":',
                        _properties,
                        ',"image":"',
                        _imageURI,
                        '","animation_url":"',
                        _animationURI,
                        '"}'
                    )
                )
            )
        );
    }

    function getTrait(
        string memory traitType,
        string memory value,
        bool includeTrailingComma
    )
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            '{"trait_type":"',
            traitType,
            '","value":',
            string.concat('"', value, '"'),
            "}",
            includeTrailingComma ? "," : ""
        );
    }

    // Encode some bytes in base64
    // https://gist.github.com/mbvissers/8ba9ac1eca9ed0ef6973bd49b3c999ba
    function encodeBase64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = BASE64_TABLE;

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
            for { } lt(dataPtr, endPtr) { } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function unpackPackedToken(uint32 packedToken) internal pure returns (UnpackedToken memory) {
        uint256 bits2Mask = (1 << 2) - 1;
        return UnpackedToken({
            palette: (packedToken >> 0) & ((1 << 7) - 1),
            facing: (packedToken >> 7) & ((1 << 1) - 1),
            depth: (packedToken >> 8) & bits2Mask,
            tileDivision: (packedToken >> 10) & bits2Mask,
            segmentSize: (packedToken >> 12) & bits2Mask,
            density: (packedToken >> 14) & bits2Mask,
            tokenArt: uint16((packedToken >> 16) & ((1 << 16) - 1))
        });
    }
}