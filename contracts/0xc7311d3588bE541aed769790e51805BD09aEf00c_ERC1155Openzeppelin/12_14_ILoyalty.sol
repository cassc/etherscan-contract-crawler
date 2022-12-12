// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0 || ^0.8.1;

/// @title Loyalty for Non-fungible token
/// @notice Manage
interface ILoyalty {
    /**
     * @notice loyalty program
     * @dev Get loyalty percentage
     * @param assetId the NFT asset identifier
     */
    function getLoyalty(uint256 assetId, address rightHolder)
        external
        view
        returns (uint256);

    /**
     * @notice loyalty program
     * @dev Check loyalty existence
     * @param assetId the NFT asset identifier
     */
    function isInLoyalty(uint256 assetId) external view returns (bool);

    function isResaleAllowed(uint256 assetId, address currentUser)
        external
        view
        returns (bool);

    function isLoyalty() external pure returns (bool);

    function getLoyaltyCreator(uint256 assetId) external view returns (address);

    function computeCreatorLoyaltyByAmount(
        uint256 assetId,
        address seller,
        uint256 sellerAmount
    ) external view returns (address creator, uint256 creatorBenif);

    event AddLoyalty(
        address collection,
        uint256 assetId,
        address rightHolder,
        uint256 percent
    );
}