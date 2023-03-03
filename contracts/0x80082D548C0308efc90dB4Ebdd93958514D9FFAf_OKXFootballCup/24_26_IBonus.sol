// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IBonus {
    function claim(
        address owner,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    function withdraw(
        address owner,
        uint256 bonusAmount,
        bytes32[] memory proof
    ) external;

    function groupStageEnds(uint256[] memory winners, uint256[] memory losers)
        external;

    function elimination(uint256 winner, uint256 loser) external;

    function setMintBonus(uint256 id, uint256 bonus) external;
}