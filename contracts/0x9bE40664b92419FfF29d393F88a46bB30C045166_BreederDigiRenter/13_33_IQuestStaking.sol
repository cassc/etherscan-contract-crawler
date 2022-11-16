// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Quest.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IQuestStaking is IERC165 {
    /**
     * @dev Emitted when a token enters or exists a quest
     */
    event QuestUpdated(
        uint256 indexed tokenId,
        address indexed tokenOwner,
        address indexed adventure,
        uint256 questId,
        bool active,
        bool booted
    );

    /**
     * @notice Allows an authorized game contract to transfer a player's token if they have opted in
     */
    function adventureTransferFrom(address from, address to, uint256 tokenId)
        external;

    /**
     * @notice Allows an authorized game contract to safe transfer a player's token if they have opted in
     */
    function adventureSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        external;

    /**
     * @notice Allows an authorized game contract to burn a player's token if they have opted in
     */
    function adventureBurn(uint256 tokenId) external;

    /**
     * @notice Allows an authorized game contract to stake a player's token into a quest if they have opted in
     */
    function enterQuest(uint256 tokenId, uint256 questId) external;

    /**
     * @notice Allows an authorized game contract to unstake a player's token from a quest if they have opted in
     */
    function exitQuest(uint256 tokenId, uint256 questId) external;

    /**
     * @notice Returns the number of quests a token is actively participating in for a specified adventure
     */
    function getQuestCount(uint256 tokenId, address adventure)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the amount of time a token has been participating in the specified quest
     */
    function getTimeOnQuest(uint256 tokenId, address adventure, uint256 questId)
        external
        view
        returns (uint256);

    /**
     * @notice Returns whether or not a token is currently participating in the specified quest as well as the time it was started and the quest index
     */
    function isParticipatingInQuest(
        uint256 tokenId,
        address adventure,
        uint256 questId
    )
        external
        view
        returns (
            bool participatingInQuest,
            uint256 startTimestamp,
            uint256 index
        );

    /**
     * @notice Returns a list of all active quests for the specified token id and adventure
     */
    function getActiveQuests(uint256 tokenId, address adventure)
        external
        view
        returns (Quest[] memory activeQuests);
}