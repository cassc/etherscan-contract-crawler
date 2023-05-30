// SPDX-License-Identifier: CC-BY-4.0
pragma solidity ^0.8.0;

interface IPrizeAssets {
    function getPrize(uint ranking, address wallet, uint tokenId) external pure returns (string memory _json);
}