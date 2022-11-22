// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

interface ICNPRebornGimmick {
    event Change(address indexed user, uint256 indexed tokenId);

    event Born(
        address indexed user,
        uint256 indexed parent1,
        uint256 indexed parent2
    );

    event Reborn(
        address indexed user,
        uint256 parent1,
        uint256 parent2,
        uint256 indexed minted1,
        uint256 indexed minted2
    );

    struct Parents {
        uint256 parent1;
        uint256 parent2;
    }

    function change(uint256[] calldata tokenIds, uint256[] calldata couponIds)
        external
        payable;

    // == For gimmick of Born
    function born(Parents[] calldata parents, uint256[] calldata couponIds)
        external
        payable;

    // == For gimmick of Reborn
    function reborn(
        address user,
        Parents[] calldata parents,
        uint256[] calldata couponIds
    ) external payable;
}