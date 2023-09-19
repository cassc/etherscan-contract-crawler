// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ITeamNFTRenderer {
    function render(uint256 tokenId) external pure returns (string memory);

    function contractURI() external pure returns (string memory);
}