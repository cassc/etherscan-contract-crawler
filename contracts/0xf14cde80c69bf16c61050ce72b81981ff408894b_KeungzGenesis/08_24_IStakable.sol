// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IStakable {
    function stake(uint256 tokenId) external;

    function unstake(uint256 tokenId) external;

    function setTokensStakeStatus(
        uint256[] memory tokenIds,
        bool setStake
    ) external;

    function setCanStake(bool b) external;

    function tokensLastStakedAtMultiple(
        uint256[] calldata tokenIds
    ) external view returns (uint256[] memory);
}