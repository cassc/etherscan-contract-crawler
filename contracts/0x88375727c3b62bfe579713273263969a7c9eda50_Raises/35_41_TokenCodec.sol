// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TokenData, TokenType} from "../../structs/TokenData.sol";
import {ONE_BYTE, ONE_BYTE_MASK, THIRTY_BYTE_MASK} from "../../constants/Codecs.sol";

//   |------------ Token data is encoded in 32 bytes ---------------|
// 0x0000000000000000000000000000000000000000000000000000000000000000
//   1 byte token type                                             tt
//   1 byte encoding version                                     vv
//   |------------------ 30 byte data region -------------------|

uint256 constant TOKEN_TYPE_SIZE = ONE_BYTE;
uint256 constant ENCODING_SIZE = ONE_BYTE;

uint256 constant ENCODING_OFFSET = TOKEN_TYPE_SIZE;
uint256 constant DATA_OFFSET = ENCODING_OFFSET + ENCODING_SIZE;

uint256 constant TOKEN_TYPE_MASK = ONE_BYTE_MASK;
uint256 constant ENCODING_VERSION_MASK = ONE_BYTE_MASK << ENCODING_OFFSET;
uint256 constant DATA_REGION_MASK = THIRTY_BYTE_MASK << DATA_OFFSET;

/// @title RaiseCodec - Token encoder/decoder
/// @notice Converts between token ID and TokenData struct.
library TokenCodec {
    function encode(TokenData memory token) internal pure returns (uint256) {
        bytes memory encoded = abi.encodePacked(token.data, token.encodingVersion, token.tokenType);
        return uint256(bytes32(encoded));
    }

    function decode(uint256 tokenId) internal pure returns (TokenData memory) {
        TokenType tokenType = TokenType(tokenId & TOKEN_TYPE_MASK);
        uint8 encodingVersion = uint8((tokenId & ENCODING_VERSION_MASK) >> ENCODING_OFFSET);
        bytes30 data = bytes30(uint240((tokenId & DATA_REGION_MASK) >> DATA_OFFSET));

        return TokenData({tokenType: tokenType, encodingVersion: encodingVersion, data: data});
    }
}