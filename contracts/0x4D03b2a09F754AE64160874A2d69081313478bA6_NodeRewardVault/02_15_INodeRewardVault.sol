// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

  /**
   * @title Interface for NodeRewardVault
   * @notice Vault will manage methods for rewards, commissions, tax
   */
interface INodeRewardVault {
    struct RewardMetadata {
        uint256 value;
        uint256 height;
    }

    function nftContract() external view returns (address);

    function rewards(uint256 tokenId) external view returns (uint256);

    function rewardsHeight() external view returns (uint256);

    function rewardsAndHeights(uint256 amt) external view returns (RewardMetadata[] memory);

    function comission() external view returns (uint256);

    function tax() external view returns (uint256);

    function dao() external view returns (address);
    
    function authority() external view returns (address);

    function aggregator() external view returns (address);

    function settle() external;

    function publicSettle() external;

    function claimRewards(uint256 tokenId) external;
}