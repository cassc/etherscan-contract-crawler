// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ICvgTokeStaking is IERC721Enumerable {
    //structs
    struct CycleTokenInfo {
        uint256 amountStaked;
        bool rewardsClaimed;
    }
    struct CycleInfo {
        uint256[] rewardsAmounts;
        uint256 totalStaked;
        mapping(uint256 => CycleTokenInfo) nftInfo;
    }
    struct TokenStakingInfo {
        uint256[] cvgActionCycleIds;
        uint256[] tokeActionCycleIds;
    }

    function getRewardsForTokeCycle(uint256 _cycleId) external view returns (uint256[] memory);

    function getTokenInfoForCycle(uint256 tokenId, uint256 _cycleId) external view returns (CycleTokenInfo memory);

    function assets() external view returns (uint256);

    function cvgStakingCycle() external view returns (uint256);

    function tokeStakingCycle() external view returns (uint256);

    function tokenTotalStaked(uint256 tokenId) external view returns (uint256 amount);

    function findTokenStakedAmountForCvgCycle(uint256 tokenId, uint256 _cycleId) external view returns (uint256);

    function findTokenStakedAmountForTokeCycle(uint256 tokenId, uint256 _cycleId) external view returns (uint256);

    //external
    function deposit(uint256 tokenId, uint256 amount, address operator) external;

    function withdraw(uint256 tokenId, uint256 amount) external;

    function claimCvgRewards(uint256 tokenId, uint256 _cycleId) external;

    function claimTokeRewards(uint256 tokenId, uint256 _cycleId) external;

    function claimMultipleCvgRewards(uint256 tokenId, uint256[] memory _cycleIds, address operator) external;

    function claimMultipleTokeRewards(
        uint256 tokenId,
        uint256[] memory _cycleIds,
        address operator,
        bool _isConvert,
        bool _isMint
    ) external;

    //OnlyStaker
    function updateTokeStakingCycle() external;

    function processTokeRewards(uint256[] memory amounts, uint256 tokeStakingCycle) external;

    //OnlyOwner
    function togglePause() external;
}