// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IRoyaltySplitter {
    struct Royalty {
        address payable payee;
        uint96 share;
    }

    function registerRoyalty(
        address collection,
        uint256 tokenId,
        Royalty[] calldata royalties
    ) external returns (address royaltyForwarder, uint96 totalShares);

    function releaseRoyalty() external payable;
}