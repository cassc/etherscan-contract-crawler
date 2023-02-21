// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interface/IESMET.sol";

abstract contract ESMET721StorageV1 {
    /**
     * @notice Base URI
     */
    string public baseTokenURI;

    /**
     * @notice ESMET contract
     */
    IESMET public esMET;

    /**
     * @notice Tracks the next token id to mint
     */
    uint256 public nextTokenId;
}