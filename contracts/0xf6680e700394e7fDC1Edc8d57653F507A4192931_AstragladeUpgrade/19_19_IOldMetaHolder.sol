//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IOldMetaHolder
/// @author Simon Fremaux (@dievardump)
interface IOldMetaHolder {
    function get(uint256 tokenId)
        external
        pure
        returns (
            uint256,
            string memory,
            string memory
        );
}