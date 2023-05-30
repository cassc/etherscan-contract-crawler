// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Enum representing token types. The V1 protocol supports only one
/// token type, "Raise," which represents a crowdfund contribution. However,
/// new token types may be added in the future.
enum TokenType {Raise}

/// @param data 30-byte data region containing encoded token data. The specific
/// format of this data depends on encoding version and token type.
/// @param encodingVersion Encoding version of this token.
/// @param tokenType Enum indicating type of this token. (e.g. Raise)
struct TokenData {
    bytes30 data;
    uint8 encodingVersion;
    TokenType tokenType;
}