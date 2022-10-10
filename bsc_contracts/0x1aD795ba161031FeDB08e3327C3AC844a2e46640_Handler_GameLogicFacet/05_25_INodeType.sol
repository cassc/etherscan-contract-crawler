// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

interface INodeType {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function burnFrom(address from, uint256[] memory tokenIds)
        external
        returns (uint256);

    function createNodeWithLuckyBox(
        address user,
        uint256[] memory tokenIds,
        string memory feature
    ) external;

    function createNodeCustom(
        address user,
        uint256[] memory tokenIds,
        string memory feature,
        uint256 feature_index
    ) external;

    function getTotalNodesNumberOf(address user)
        external
        view
        returns (uint256);

    function getAttribute(uint256 tokenId)
        external
        view
        returns (string memory);

    function claimRewardsAll(address user) external returns (uint256, uint256);

    function claimRewardsBatch(address user, uint256[] memory tokenIds)
        external
        returns (uint256, uint256);

    function calculateUserRewards(address user)
        external
        view
        returns (uint256, uint256);

    function applyWaterpackBatch(
        address user,
        uint256[] memory tokenIds,
        uint256 ratioOfGRPExtended,
        uint256[] memory amounts
    ) external;

    function applyFertilizerBatch(
        address user,
        uint256[] memory tokenIds,
        uint256 durationEffect,
        uint256 boostAmount,
        uint256[] memory amounts
    ) external;

    function setPlotAdditionalLifetime(
        address user,
        uint256 tokenId,
        uint256 amountOfGRP
    ) external;

    function addPlotAdditionalLifetime(
        address user,
        uint256 tokenId,
        uint256 amountOfGRP,
        uint256 amount
    ) external;

    function name() external view returns (string memory);

    function totalCreatedNodes() external view returns (uint256);
    
    function setBlockRewards(uint256 tokenId, bool _block) external;
}