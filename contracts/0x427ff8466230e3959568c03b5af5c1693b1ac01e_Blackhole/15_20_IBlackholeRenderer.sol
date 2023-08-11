// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

interface IBlackholeRenderer {
    function renderSVG(
        uint256 randomness,
        uint256 tokenId,
        bool showStar
    ) external pure returns (string memory);
}