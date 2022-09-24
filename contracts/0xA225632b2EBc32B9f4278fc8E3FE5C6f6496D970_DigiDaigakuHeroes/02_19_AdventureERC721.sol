// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IQuestStaking.sol";
import "./AdventurePermissions.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract AdventureERC721 is ERC721, AdventurePermissions, IQuestStaking {

    uint256 public constant MAX_UINT32 = type(uint32).max;
    uint256 public constant MAX_CONCURRENT_QUESTS = 100;

    /// @dev Maps each token id to a mapping that can enumerate all active quests within an adventure
    mapping (uint256 => mapping (address => uint32[])) public activeQuestList;

    /// @dev Maps each token id to a mapping from adventure address to a mapping of quest ids to quest details
    mapping (uint256 => mapping (address => mapping (uint32 => Quest))) public activeQuestLookup;

    /// @dev Maps each token id to the number of blocking quests it is currently entered into
    mapping (uint256 => uint256) public blockingQuestCounts;

    /// @dev ERC-165 interface support
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721, IERC165) returns (bool) {
        return interfaceId == type(IQuestStaking).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice Allows an authorized game contract to transfer a player's token if they have opted in
    function adventureTransferFrom(address from, address to, uint256 tokenId) external override onlyAdventure {
        require(_isApprovedForAdventure(_msgSender(), tokenId), "Caller not approved for adventure");
        _transfer(from, to, tokenId);
    }

    /// @notice Allows an authorized game contract to transfer a player's token if they have opted in
    function adventureSafeTransferFrom(address from, address to, uint256 tokenId) external override onlyAdventure {
        require(_isApprovedForAdventure(_msgSender(), tokenId), "Caller not approved for adventure");
        _safeTransfer(from, to, tokenId, "");
    }

    /// @notice Allows an authorized game contract to burn a player's token if they have opted in
    function adventureBurn(uint256 tokenId) external override onlyAdventure {
        require(_isApprovedForAdventure(_msgSender(), tokenId), "Caller not approved for adventure");
        _burn(tokenId);
    }

    /// @notice Allows an authorized game contract to stake a player's token into a quest if they have opted in
    function enterQuest(uint256 tokenId, uint256 questId) external override onlyAdventure {
        require(_isApprovedForAdventure(_msgSender(), tokenId), "Caller not approved for adventure");
        _enterQuest(tokenId, _msgSender(), questId);
    }

    /// @notice Allows an authorized game contract to unstake a player's token from a quest if they have opted in
    /// For developers of adventure contracts that perform adventure burns, be aware that the adventure must exitQuest
    /// before the adventure burn occurs, as _exitQuest emits the owner of the token, which would revert after burning.
    function exitQuest(uint256 tokenId, uint256 questId) external override onlyAdventure {
        require(_isApprovedForAdventure(_msgSender(), tokenId), "Caller not approved for adventure");
        _exitQuest(tokenId, _msgSender(), questId);
    }

    /// @notice Admin-only ability to boot a token from all quests on an adventure.
    /// This ability is only unlocked in the event that an adventure has been unwhitelisted, as early exiting
    /// from quests can cause out of sync state between the ERC721 token contract and the adventure/quest.
    function bootFromAllQuests(uint256 tokenId, address adventure) external onlyOwner onlyWhenRemovedFromWhitelist(adventure) {
        _exitAllQuests(tokenId, adventure, true);
    }

    /// @notice Gives the player the ability to exit a quest without interacting directly with the approved, whitelisted adventure
    /// This ability is only unlocked in the event that an adventure has been unwhitelisted, as early exiting
    /// from quests can cause out of sync state between the ERC721 token contract and the adventure/quest.
    function userExitQuest(uint256 tokenId, address adventure, uint256 questId) external onlyWhenRemovedFromWhitelist(adventure) {
        require(ownerOf(tokenId) == _msgSender(), "Only token owner may exit quest");
        _exitQuest(tokenId, adventure, questId);
    }

    /// @notice Gives the player the ability to exit all quests on an adventure without interacting directly with the approved, whitelisted adventure
    /// This ability is only unlocked in the event that an adventure has been unwhitelisted, as early exiting
    /// from quests can cause out of sync state between the ERC721 token contract and the adventure/quest.
    function userExitAllQuests(uint256 tokenId, address adventure) external onlyWhenRemovedFromWhitelist(adventure) {
        require(ownerOf(tokenId) == _msgSender(), "Only token owner may exit quest");
        _exitAllQuests(tokenId, adventure, false);
    }
    
    /// @notice Returns the number of quests a token is actively participating in for a specified adventure
    function getQuestCount(uint256 tokenId, address adventure) public override view returns (uint256) {
        return activeQuestList[tokenId][adventure].length;
    }

    /// @notice Returns the amount of time a token has been participating in the specified quest
    function getTimeOnQuest(uint256 tokenId, address adventure, uint256 questId) public override view returns (uint256) {
        (bool participatingInQuest, uint256 startTimestamp,) = isParticipatingInQuest(tokenId, adventure, questId);
        return participatingInQuest ? (block.timestamp - startTimestamp) : 0;
    } 

    /// @notice Returns whether or not a token is currently participating in the specified quest as well as the time it was started and the quest index
    function isParticipatingInQuest(uint256 tokenId, address adventure, uint256 questId) public override view returns (bool participatingInQuest, uint256 startTimestamp, uint256 index) {
        Quest memory quest = activeQuestLookup[tokenId][adventure][uint32(questId)];
        participatingInQuest = quest.isActive;
        startTimestamp = quest.startTimestamp;
        index = quest.arrayIndex;
        return (participatingInQuest, startTimestamp, index);
    }

    /// @notice Returns a list of all active quests for the specified token id and adventure
    function getActiveQuests(uint256 tokenId, address adventure) public override view returns (Quest[] memory activeQuests) {
        uint256 questCount = getQuestCount(tokenId, adventure);
        activeQuests = new Quest[](questCount);
        uint32[] memory activeQuestIdList = activeQuestList[tokenId][adventure];

        for(uint256 i = 0; i < questCount; ++i) {
            activeQuests[i] = activeQuestLookup[tokenId][adventure][activeQuestIdList[i]];
        }

        return activeQuests;
    }

    /// @notice Enters the specified quest for a token id.
    /// Throws if the token is already participating in the specified quest.
    /// Throws if the number of active quests exceeds the max allowable for the given adventure.
    /// Emits a QuestUpdated event for off-chain processing.
    function _enterQuest(uint256 tokenId, address adventure, uint256 questId) internal {
        require(questId <= MAX_UINT32, "questId out of range");

        (bool participatingInQuest,,) = isParticipatingInQuest(tokenId, adventure, questId);
        require(!participatingInQuest, "Already on quest");

        uint256 currentQuestCount = getQuestCount(tokenId, adventure);
        require(currentQuestCount < MAX_CONCURRENT_QUESTS, "Too many active quests");

        uint32 castedQuestId = uint32(questId);
        activeQuestList[tokenId][adventure].push(castedQuestId);
        activeQuestLookup[tokenId][adventure][castedQuestId] = Quest({
            isActive: true,
            startTimestamp: uint64(block.timestamp),
            questId: castedQuestId,
            arrayIndex: uint32(currentQuestCount)
        });

        address ownerOfToken = ownerOf(tokenId);
        emit QuestUpdated(tokenId, ownerOfToken, adventure, questId, true, false);

        if(IAdventure(adventure).questsLockTokens()) {
            unchecked {
                ++blockingQuestCounts[tokenId];
            }
        }

        IAdventure(adventure).onQuestEntered(ownerOfToken, tokenId, questId);
    }

    /// @notice Exits the specified quest for a token id.
    /// Throws if the token is not currently participating on the specified quest.
    /// Emits a QuestUpdated event for off-chain processing.
    function _exitQuest(uint256 tokenId, address adventure, uint256 questId) internal {
        require(questId <= MAX_UINT32, "questId out of range");

        (bool participatingInQuest, uint256 startTimestamp, uint256 index) = isParticipatingInQuest(tokenId, adventure, questId);
        require(participatingInQuest, "Not on quest");

        uint32 castedQuestId = uint32(questId);
        uint256 lastArrayIndex = getQuestCount(tokenId, adventure) - 1;
        activeQuestList[tokenId][adventure][index] = activeQuestList[tokenId][adventure][lastArrayIndex];
        activeQuestLookup[tokenId][adventure][activeQuestList[tokenId][adventure][lastArrayIndex]].arrayIndex = uint32(index);

        
        activeQuestList[tokenId][adventure].pop();
        delete activeQuestLookup[tokenId][adventure][castedQuestId];

        address ownerOfToken = ownerOf(tokenId);
        emit QuestUpdated(tokenId, ownerOfToken, adventure, questId, false, false);

        if(IAdventure(adventure).questsLockTokens()) {
            --blockingQuestCounts[tokenId];
        }

        IAdventure(adventure).onQuestExited(ownerOfToken, tokenId, questId, startTimestamp);
    }

    /// @notice Removes the specified token id from all quests on the specified adventure
    function _exitAllQuests(uint256 tokenId, address adventure, bool booted) internal {
        address tokenOwner = ownerOf(tokenId);
        uint256 questCount = getQuestCount(tokenId, adventure);

        if(IAdventure(adventure).questsLockTokens()) {
            blockingQuestCounts[tokenId] -= questCount;
        }

        for(uint256 i = 0; i < questCount; ++i) {
            uint256 questId = activeQuestList[tokenId][adventure][i];

            Quest memory quest = activeQuestLookup[tokenId][adventure][uint32(questId)];
            uint256 startTimestamp = quest.startTimestamp;

            emit QuestUpdated(tokenId, tokenOwner, adventure, questId, false, booted);
            delete activeQuestLookup[tokenId][adventure][uint32(questId)];
            
            IAdventure(adventure).onQuestExited(tokenOwner, tokenId, questId, startTimestamp);
        }

        delete activeQuestList[tokenId][adventure];
    }

    /// @dev By default, tokens that are participating in quests are transferrable.  However, if a token is participating
    /// in a quest on an adventure that was designated as a token locker, the transfer will revert and keep the token
    /// locked.
    function _beforeTokenTransfer(address /*from*/, address /*to*/, uint256 tokenId) internal virtual override {
        require(blockingQuestCounts[tokenId] == 0, "An active quest is preventing transfers");
    }
}