// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "./ITokeRewards.sol";
import "./ITAssetStruct.sol";
import "./ICvgControlTower.sol";
import "./IStakingLogo.sol";

interface ITAssetStaking is IERC721Enumerable {
    struct StakingInfo {
        uint256 tokenId;
        string symbol;
        uint256 pending;
        uint256 totalStaked;
        uint256 cvgClaimable;
        uint256[] tokeClaimable;
    }

    function processTokeRewards(uint256 amount, uint256 tokeCycle) external;

    function getGlobalViewTokeStaking() external view returns (ITAssetStruct.TAssetGlobalView memory);

    function deposit(uint256 tokenId, uint256 amount, address operator) external;

    function initialize(ICvgControlTower _cvgControlTower, IERC20Metadata _tAsset, string memory setSymbol) external;

    function claimMultipleCvgRewards(uint256 tokenId, uint256[] memory _cycleIds) external;

    function claimMultipleTokeRewards(
        uint256 tokenId,
        uint256[] memory _cycleIds,
        bool _isConvert,
        bool _isMint
    ) external;

    function stakingInfo(uint256 tokenId) external view returns (StakingInfo memory);

    function checkBurn(uint256 tokenId) external view;
}