// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

abstract contract IMetadata {
    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        returns (string memory);
}