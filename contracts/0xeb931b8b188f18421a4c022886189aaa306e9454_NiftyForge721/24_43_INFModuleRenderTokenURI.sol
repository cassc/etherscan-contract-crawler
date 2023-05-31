//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface INFModuleRenderTokenURI {
    function renderTokenURI(uint256 tokenId)
        external
        view
        returns (string memory);

    function renderTokenURI(address registry, uint256 tokenId)
        external
        view
        returns (string memory);
}