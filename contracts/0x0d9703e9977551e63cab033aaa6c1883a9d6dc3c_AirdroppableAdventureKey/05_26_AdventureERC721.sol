// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAdventurous.sol";
import "./AdventurePermissions.sol";
import "../initializable/IAdventureERC721Initializer.sol";
import "../utils/tokens/InitializableERC721.sol";

error AlreadyInitializedAdventureERC721();
error AlreadyOnQuest();
error AnActiveQuestIsPreventingTransfers();
error CallerNotTokenOwner();
error MaxSimultaneousQuestsCannotBeZero();
error MaxSimultaneousQuestsExceeded();
error NotOnQuest();
error QuestIdOutOfRange();
error TooManyActiveQuests();

/**
 * @title AdventureERC721
 * @author Limit Break, Inc.
 * @notice Implements the {IAdventurous} token standard for ERC721-compliant tokens.
 * @dev Inherits {InitializableERC721} to provide the option to support EIP-1167.
 */
abstract contract AdventureERC721 is InitializableERC721, AdventurePermissions, IAdventurous, IAdventureERC721Initializer {

    uint256 public constant MAX_UINT32 = type(uint32).max;

    /// @notice Specifies an upper bound for the maximum number of simultaneous quests.
    uint256 public constant MAX_CONCURRENT_QUESTS = 100;

    /// @notice Specifies whether or not the contract is initialized
    bool public initializedAdventureERC721;

    /// @dev The most simultaneous quests the token may participate in at a time
    uint256 public maxSimultaneousQuests;

    /// @dev Maps each token id to a mapping that can enumerate all active quests within an adventure
    mapping (uint256 => mapping (address => uint32[])) public activeQuestList;

    /// @dev Maps each token id to a mapping from adventure address to a mapping of quest ids to quest details
    mapping (uint256 => mapping (address => mapping (uint32 => Quest))) public activeQuestLookup;

    /// @dev Maps each token id to the number of blocking quests it is currently entered into
    mapping (uint256 => uint256) public blockingQuestCounts;

    /// @dev Initializes parameters of AdventureERC721 tokens.
    /// These cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    function initializeAdventureERC721(uint256 maxSimultaneousQuests_) public override onlyOwner {
        if(initializedAdventureERC721) {
            revert AlreadyInitializedAdventureERC721();
        }

        _validateMaxSimultaneousQuests(maxSimultaneousQuests_);
        maxSimultaneousQuests = maxSimultaneousQuests_;

        initializedAdventureERC721 = true;
    }

    /// @dev ERC-165 interface support
    function supportsInterface(bytes4 interfaceId) public view virtual override (InitializableERC721, IERC165) returns (bool) {
        return 
        interfaceId == type(IAdventurous).interfaceId || 
        interfaceId == type(IAdventureERC721Initializer).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /// @notice Allows an authorized game contract to transfer a player's token if they have opted in
    function adventureTransferFrom(address from, address to, uint256 tokenId) external override {
        _requireCallerIsWhitelistedAdventure();
        _requireCallerApprovedForAdventure(tokenId);
        _transfer(from, to, tokenId);
    }

    /// @notice Allows an authorized game contract to transfer a player's token if they have opted in
    function adventureSafeTransferFrom(address from, address to, uint256 tokenId) external override {
        _requireCallerIsWhitelistedAdventure();
        _requireCallerApprovedForAdventure(tokenId);
        _safeTransfer(from, to, tokenId, "");
    }

    /// @notice Allows an authorized game contract to burn a player's token if they have opted in
    function adventureBurn(uint256 tokenId) external override {
        _requireCallerIsWhitelistedAdventure();
        _requireCallerApprovedForAdventure(tokenId);
        _burn(tokenId);
    }

    /// @notice Allows an authorized game contract to enter a player's token into a quest if they have opted in
    function enterQuest(uint256 tokenId, uint256 questId) external override {
        _requireCallerIsWhitelistedAdventure();
        _requireCallerApprovedForAdventure(tokenId);
        _enterQuest(tokenId, _msgSender(), questId);
    }

    /// @notice Allows an authorized game contract to exit a player's token from a quest if they have opted in
    /// For developers of adventure contracts that perform adventure burns, be aware that the adventure must exitQuest
    /// before the adventure burn occurs, as _exitQuest emits the owner of the token, which would revert after burning.
    function exitQuest(uint256 tokenId, uint256 questId) external override {
        _requireCallerIsWhitelistedAdventure();
        _requireCallerApprovedForAdventure(tokenId);
        _exitQuest(tokenId, _msgSender(), questId);
    }

    /// @notice Admin-only ability to boot a token from all quests on an adventure.
    /// This ability is only unlocked in the event that an adventure has been unwhitelisted, as early exiting
    /// from quests can cause out of sync state between the ERC721 token contract and the adventure/quest.
    function bootFromAllQuests(uint256 tokenId, address adventure) external onlyOwner {
        _requireAdventureRemovedFromWhitelist(adventure);
        _exitAllQuests(tokenId, adventure, true);
    }

    /// @notice Gives the player the ability to exit a quest without interacting directly with the approved, whitelisted adventure
    /// This ability is only unlocked in the event that an adventure has been unwhitelisted, as early exiting
    /// from quests can cause out of sync state between the ERC721 token contract and the adventure/quest.
    function userExitQuest(uint256 tokenId, address adventure, uint256 questId) external {
        _requireAdventureRemovedFromWhitelist(adventure);
        _requireCallerOwnsToken(tokenId);
        _exitQuest(tokenId, adventure, questId);
    }

    /// @notice Gives the player the ability to exit all quests on an adventure without interacting directly with the approved, whitelisted adventure
    /// This ability is only unlocked in the event that an adventure has been unwhitelisted, as early exiting
    /// from quests can cause out of sync state between the ERC721 token contract and the adventure/quest.
    function userExitAllQuests(uint256 tokenId, address adventure) external {
        _requireAdventureRemovedFromWhitelist(adventure);
        _requireCallerOwnsToken(tokenId);
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

    /// @dev Enters the specified quest for a token id.
    /// Throws if the token is already participating in the specified quest.
    /// Throws if the number of active quests exceeds the max allowable for the given adventure.
    /// Emits a QuestUpdated event for off-chain processing.
    function _enterQuest(uint256 tokenId, address adventure, uint256 questId) internal {
        _requireValidQuestId(questId);

        (bool participatingInQuest,,) = isParticipatingInQuest(tokenId, adventure, questId);
        if(participatingInQuest) {
            revert AlreadyOnQuest();
        }

        uint256 currentQuestCount = getQuestCount(tokenId, adventure);
        if(currentQuestCount == maxSimultaneousQuests) {
            revert TooManyActiveQuests();
        }

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

        // Invoke callback to the adventure to facilitate state synchronization as needed
        IAdventure(adventure).onQuestEntered(ownerOfToken, tokenId, questId);
    }

    /// @dev Exits the specified quest for a token id.
    /// Throws if the token is not currently participating on the specified quest.
    /// Emits a QuestUpdated event for off-chain processing.
    function _exitQuest(uint256 tokenId, address adventure, uint256 questId) internal {
        _requireValidQuestId(questId);

        (bool participatingInQuest, uint256 startTimestamp, uint256 index) = isParticipatingInQuest(tokenId, adventure, questId);
        if(!participatingInQuest) {
            revert NotOnQuest();
        }

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

        // Invoke callback to the adventure to facilitate state synchronization as needed
        IAdventure(adventure).onQuestExited(ownerOfToken, tokenId, questId, startTimestamp);
    }

    /// @dev Removes the specified token id from all quests on the specified adventure
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
            
            // Invoke callback to the adventure to facilitate state synchronization as needed
            IAdventure(adventure).onQuestExited(tokenOwner, tokenId, questId, startTimestamp);
        }

        delete activeQuestList[tokenId][adventure];
    }

    /// @dev By default, tokens that are participating in quests are transferrable.  However, if a token is participating
    /// in a quest on an adventure that was designated as a token locker, the transfer will revert and keep the token
    /// locked.
    function _beforeTokenTransfer(address /*from*/, address /*to*/, uint256 tokenId) internal virtual override {        
        if(blockingQuestCounts[tokenId] > 0) {
            revert AnActiveQuestIsPreventingTransfers();
        }
    }

    /// @dev Validates that the caller owns the specified token
    /// Throws when the caller does not own the specified token.
    function _requireCallerOwnsToken(uint256 tokenId) internal view {
        if(ownerOf(tokenId) != _msgSender()) {
            revert CallerNotTokenOwner();
        }
    }

    /// @dev Validates that the specified quest id does not overflow a uint32
    /// Throws when questId exceeds the largest uint32 value.
    function _requireValidQuestId(uint256 questId) internal pure {
        if(questId > MAX_UINT32) {
            revert QuestIdOutOfRange();
        }
    }

    /// @dev Validates that the specified value of max simultaneous quests is in range [1-MAX_CONCURRENT_QUESTS]
    /// Throws when `maxSimultaneousQuests_` is zero.
    /// Throws when `maxSimultaneousQuests_` is more than MAX_CONCURRENT_QUESTS.
    function _validateMaxSimultaneousQuests(uint256 maxSimultaneousQuests_) internal pure {
        if(maxSimultaneousQuests_ == 0) {
            revert MaxSimultaneousQuestsCannotBeZero();
        }

        if(maxSimultaneousQuests_ > MAX_CONCURRENT_QUESTS) {
            revert MaxSimultaneousQuestsExceeded();
        }
    }
}