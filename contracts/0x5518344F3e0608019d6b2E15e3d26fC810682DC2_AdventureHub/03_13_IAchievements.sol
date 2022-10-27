// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";

/**
 * @title IAchievements
 * @author Limit Break, Inc.
 * @notice Interface for the Achievements token contract
 */
interface IAchievements is IERC1155MetadataURI {
 
    /// @dev Reserves an achievement id and associates the achievement id with a single allowed minter.
    function reserveAchievementId(string calldata metadataURI) external returns (uint256);

    /// @dev Mints an achievement of type `id` to the `to` address.
    function mint(address to, uint256 id, uint256 amount) external;

    /// @dev Batch mints achievements to the `to` address.
    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts) external;
}