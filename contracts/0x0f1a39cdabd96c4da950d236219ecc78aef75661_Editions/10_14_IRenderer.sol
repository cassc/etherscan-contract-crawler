// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IRenderer {
    function tokenURI(uint256 tokenId) external view returns (string calldata);

    function contractURI() external view returns (string calldata);
}