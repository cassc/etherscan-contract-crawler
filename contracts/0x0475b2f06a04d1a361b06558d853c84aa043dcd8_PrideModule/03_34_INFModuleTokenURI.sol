//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface INFModuleTokenURI {
    function tokenURI(address registry, uint256 tokenId)
        external
        view
        returns (string memory);
}