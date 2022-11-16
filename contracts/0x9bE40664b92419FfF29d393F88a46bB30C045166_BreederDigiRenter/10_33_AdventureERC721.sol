// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IQuestStaking.sol";
import "./AdventurePermissions.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract AdventureERC721 is
    ERC721,
    AdventurePermissions,
    IQuestStaking
{
    uint256 private constant MAX_UINT = type(uint256).max;
    uint256 public constant MAX_CONCURRENT_QUESTS = 100;

    /// @dev Maps each token id to a variable that maps adventures to quests that are active
    mapping(uint256 => mapping(address => Quest[])) public quests;

    /// @dev ERC-165 interface support
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC721, IERC165)
        returns (bool)
    {
        return interfaceId == type(IQuestStaking).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice Allows an authorized game contract to transfer a player's token if they have opted in
    function adventureTransferFrom(address from, address to, uint256 tokenId)
        external
        override
        onlyAdventure
    {
        require(_isApprovedForAdventure(_msgSender(), tokenId), "Caller not approved for adventure");
        _transfer(from, to, tokenId);
    }

    /// @notice Allows an authorized game contract to transfer a player's token if they have opted in
    function adventureSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        external
        override
        onlyAdventure
    {
        require(_isApprovedForAdventure(_msgSender(), tokenId), "Caller not approved for adventure");
        _safeTransfer(from, to, tokenId, "");
    }

    /// @notice Allows an authorized game contract to burn a player's token if they have opted in
    function adventureBurn(uint256 tokenId) external override onlyAdventure {
        require(_isApprovedForAdventure(_msgSender(), tokenId), "Caller not approved for adventure");
        _burn(tokenId);
    }

    /// @notice Allows an authorized game contract to stake a player's token into a quest if they have opted in
    function enterQuest(uint256 tokenId, uint256 questId)
        external
        override
        onlyAdventure
    {
        require(_isApprovedForAdventure(_msgSender(), tokenId), "Caller not approved for adventure");
        _enterQuest(tokenId, _msgSender(), questId);
    }

    /// @notice Allows an authorized game contract to unstake a player's token from a quest if they have opted in
    function exitQuest(uint256 tokenId, uint256 questId)
        external
        override
        onlyAdventure
    {
        require(_isApprovedForAdventure(_msgSender(), tokenId), "Caller not approved for adventure");
        _exitQuest(tokenId, _msgSender(), questId);
    }

    /// @notice Admin-only ability to boot a token from all quests on an adventure.
    /// This allows booting the token from staking if abuse is detected.
    function bootFromAllQuests(uint256 tokenId, address adventure)
        external
        onlyOwner
    {
        _exitAllQuests(tokenId, adventure, true);
    }

    /// @notice Gives the player the ability to exit a quest without interacting directly with the approved, whitelisted adventure
    function userExitQuest(uint256 tokenId, address adventure, uint256 questId)
        external
    {
        require(ownerOf(tokenId) == _msgSender(), "Only token owner may exit quest");
        _exitQuest(tokenId, adventure, questId);
    }

    /// @notice Gives the player the ability to exit all quests on an adventure without interacting directly with the approved, whitelisted adventure
    function userExitAllQuests(uint256 tokenId, address adventure) external {
        require(ownerOf(tokenId) == _msgSender(), "Only token owner may exit quest");
        _exitAllQuests(tokenId, adventure, false);
    }

    /// @notice Returns the number of quests a token is actively participating in for a specified adventure
    function getQuestCount(uint256 tokenId, address adventure)
        public
        view
        override
        returns (uint256)
    {
        return quests[tokenId][adventure].length;
    }

    /// @notice Returns the amount of time a token has been participating in the specified quest
    function getTimeOnQuest(uint256 tokenId, address adventure, uint256 questId)
        public
        view
        override
        returns (uint256)
    {
        (bool participatingInQuest, uint256 startTimestamp,) =
            isParticipatingInQuest(tokenId, adventure, questId);
        return participatingInQuest ? (block.timestamp - startTimestamp) : 0;
    }

    /// @notice Returns whether or not a token is currently participating in the specified quest as well as the time it was started and the quest index
    function isParticipatingInQuest(
        uint256 tokenId,
        address adventure,
        uint256 questId
    )
        public
        view
        override
        returns (
            bool participatingInQuest,
            uint256 startTimestamp,
            uint256 index
        )
    {
        index = MAX_UINT;

        Quest[] memory tokenQuestsForAdventure_ = quests[tokenId][adventure];

        for (uint256 i = 0; i < tokenQuestsForAdventure_.length; ++i) {
            Quest memory quest = tokenQuestsForAdventure_[i];
            if (quest.questId == uint64(questId)) {
                participatingInQuest = true;
                startTimestamp = quest.startTimestamp;
                index = i;
                break;
            }
        }

        return (participatingInQuest, startTimestamp, index);
    }

    /// @notice Returns a list of all active quests for the specified token id and adventure
    function getActiveQuests(uint256 tokenId, address adventure)
        public
        view
        override
        returns (Quest[] memory activeQuests)
    {
        uint256 questCount = getQuestCount(tokenId, adventure);
        activeQuests = new Quest[](questCount);

        for (uint256 i = 0; i < questCount; ++i) {
            activeQuests[i] = quests[tokenId][adventure][i];
        }

        return activeQuests;
    }

    /// @notice Enters the specified quest for a token id.
    /// Throws if the token is already participating in the specified quest.
    /// Throws if the number of active quests exceeds the max allowable for the given adventure.
    /// Emits a QuestUpdated event for off-chain processing.
    function _enterQuest(uint256 tokenId, address adventure, uint256 questId)
        internal
    {
        (bool participatingInQuest,,) =
            isParticipatingInQuest(tokenId, adventure, questId);
        require(!participatingInQuest, "Already on quest");
        require(getQuestCount(tokenId, adventure) < MAX_CONCURRENT_QUESTS, "Too many active quests");

        quests[tokenId][adventure].push(Quest({ startTimestamp: uint64(block.timestamp), questId: uint64(questId) }));

        emit
            QuestUpdated(tokenId, ownerOf(tokenId), adventure, questId, true, false);
    }

    /// @notice Exits the specified quest for a token id.
    /// Throws if the token is not currently participating on the specified quest.
    /// Emits a QuestUpdated event for off-chain processing.
    function _exitQuest(uint256 tokenId, address adventure, uint256 questId)
        internal
    {
        (bool participatingInQuest,, uint256 index) =
            isParticipatingInQuest(tokenId, adventure, questId);
        require(participatingInQuest, "Not on quest");

        // Copy last quest element to overwrite the quest to be removed and then pop the end of the quests array
        quests[tokenId][adventure][index] =
            quests[tokenId][adventure][getQuestCount(tokenId, adventure) - 1];
        quests[tokenId][adventure].pop();

        emit
            QuestUpdated(tokenId, ownerOf(tokenId), adventure, questId, false, false);
    }

    /// @notice Removes the specified token id from all quests on the specified adventure
    function _exitAllQuests(uint256 tokenId, address adventure, bool booted)
        internal
    {
        address tokenOwner = ownerOf(tokenId);
        uint256 questCount = getQuestCount(tokenId, adventure);

        for (uint256 i = 0; i < questCount; ++i) {
            emit
                QuestUpdated(tokenId, tokenOwner, adventure, quests[tokenId][adventure][i].questId, false, booted);
        }
        delete quests[tokenId][adventure];
    }

    /// @dev By default, tokens that are participating in quests are transferrable.  However, if a token is participating
    /// in a quest on an adventure that was designated as a token locker, the transfer will revert and keep the token
    /// locked.
    function _beforeTokenTransfer(
        address, /*from*/
        address, /*to*/
        uint256 tokenId
    )
        internal
        virtual
        override
    {
        address[] memory whitelistedAdventureList_ = whitelistedAdventureList;

        for (uint256 i = 0; i < whitelistedAdventureList_.length; ++i) {
            address adventure = whitelistedAdventureList_[i];
            if (getQuestCount(tokenId, adventure) > 0) {
                require(!whitelistedAdventures[adventure].questsLockTokens, "An active quest is preventing transfers");
            }
        }
    }
}