// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

abstract contract IAsuraMetadata {
    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        returns (string memory);
}