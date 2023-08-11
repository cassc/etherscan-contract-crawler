// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IRoyaltySplitter {
    struct Royalty {
        address payable payee;
        uint96 share;
    }

    function registerCollectionRoyalty(
        address collection,
        IRoyaltySplitter.Royalty[] calldata royalties
    ) external returns (address, uint96);

    function registerTokenRoyalty(
        address collection,
        uint256 tokenId,
        Royalty[] calldata royalties
    ) external returns (address royaltyForwarder, uint96 totalShares);

    function releaseRoyalty() external payable;

    function releaseRoyalty(IERC20Upgradeable token, uint256 amount) external;

    function computeCollectionRoyaltyForwarderAddress(address collection) external view returns (address);

    function computeTokenRoyaltyForwarderAddress(address collection, uint256 tokenId) external view returns (address);
}