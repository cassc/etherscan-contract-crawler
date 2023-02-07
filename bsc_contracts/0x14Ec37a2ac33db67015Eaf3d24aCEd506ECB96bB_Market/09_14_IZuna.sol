// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IZuna {
    function getTokenInfo(uint256 tokenId)
        external
        view
        returns (address creator, uint256 royaltyFee);
}