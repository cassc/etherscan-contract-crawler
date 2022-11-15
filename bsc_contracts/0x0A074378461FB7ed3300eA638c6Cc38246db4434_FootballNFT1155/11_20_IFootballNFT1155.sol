// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @title IStarNFT
 * @author Galaxy Protocol
 *
 * Interface for operating with StarNFTs.
 */
interface IFootballNFT1155 {
    /* ============ Events =============== */

    /* ============ Functions ============ */
    function withdrawPoolReward( ) external returns (uint256);
    function canWithdrawPoolReward() external view returns (uint256);
    function teamIdToTier(uint256) external view returns (uint256);
    function teamIdToName(uint256) external view returns (string memory);

    // function teamID(uint256) external view returns (uint16);
    // mint
    // function mintFullRandom(uint256 powah) external returns (uint256[] memory);
    // function mintBatch(address account, uint256 amount, uint256[] calldata powahArr) external returns (uint256[] memory);
    // function burnBatch(address account, uint256[] calldata ids) external;
}