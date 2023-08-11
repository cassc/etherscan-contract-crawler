// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IAccessControlChecker.sol";

abstract contract AbstractControlChecker is IAccessControlChecker {
    struct Token {
        address contractAddress;
        uint256 tokenId;
    }
    mapping(bytes32 => Token) public documentIdToToken;
}