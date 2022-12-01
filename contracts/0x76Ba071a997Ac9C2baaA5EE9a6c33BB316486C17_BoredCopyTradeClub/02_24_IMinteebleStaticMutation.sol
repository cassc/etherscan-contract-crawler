// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//  =============================================
//   _   _  _  _  _  ___  ___  ___  ___ _    ___
//  | \_/ || || \| ||_ _|| __|| __|| o ) |  | __|
//  | \_/ || || \\ | | | | _| | _| | o \ |_ | _|
//  |_| |_||_||_|\_| |_| |___||___||___/___||___|
//
//  Website: https://minteeble.com
//  Email: [email protected]
//
//  =============================================

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 *  Minteebke Static Mutation.
 *  -- HOW DOES IT WORK --
 *  For implementing a Minteeble Static Mutation, you'll need:
 *    -   A normal ERC721 token for the base collection
 *    -   An ERC721 token implementing IMinteebleStaticMutation for the mutated collection.
 *        The deployed contract should be later registered on the Minteeble App.
 *        Also, in the Minteeble App, you need to provide all the metadata files and images of the mutated version
 *        (1:1), so if the base collection had 10K items, you should provide all the mutated version of the items.
 */

/// @title Base interface for implementing the Minteeble static mutation
interface IMinteebleStaticMutation {
    /// @notice Determines the list of IDs the address owns on the old collection
    /// @dev Function used for determining the pairing with the old collection.
    /// Basic ERC721 does not support by default a this feature
    /// @param owner The wallet address to be checked
    /// @return List of items owned in the base collection
    function oldCollectionItems(address owner)
        external
        view
        returns (uint256[] memory);

    /// @notice Determines the mapping between IDs from new collection and IDs fron the old one
    /// @param _newId ID from the new collection
    /// @return ID from the old collection
    function oldCollectionId(uint256 _newId) external view returns (uint256);
}