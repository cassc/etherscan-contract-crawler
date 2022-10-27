// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@limit-break/achievements/contracts/IAchievements.sol";
import "limit-break-contracts/contracts/adventures/IAdventure.sol";
import "limit-break-contracts/contracts/adventures/IAdventurousERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

error AdventureKeyAlreadyActivated();
error AdventureKeyIsInactive();
error CallerNotTokenOwner();
error CannotSpecifyZeroAddressForAchievementsToken();
error NoMoreAdventureKeysCanBeActivated();
error NotAnAdventurousContract();
error NotAnERC721Contract();
error OnQuestEnteredCallbackTriggeredByAddressThatIsNotAnActiveAdventureKey();
error UnknownAdventureKey();

/**
 * @title AdventureHub
 * @author Limit Break, Inc.
 * @notice An Adventure that is compatible with all adventure keys, unlocking crossover events with any partner game.
 */
contract AdventureHub is Ownable, ERC165, IAdventure {
    
    struct KeyState {
        bool isKeyActive;
        uint32 questId;
        uint256 achievementId;
    }

    /// @dev Largest unsigned int 32 bit value
    uint256 private constant MAX_UINT32 = type(uint32).max;

    /// @dev Points to the soulbound achievements token.
    /// Players earn soulbound achievement badges for entering games using their adventure keys.
    IAchievements public immutable achievementsToken;

    /// @dev The quest id of the adventure key that was most recently activated for the first time.
    uint32 public lastQuestId;

    /// @dev Maps an adventure key contract address to its key state (activation status and associated quest id)
    mapping (address => KeyState) public adventureKeyStates;

    /// @dev Maps a quest id to the adventure key contract address it is bound to
    /// If needed, off-chain applications can enumerate over this mapping using `lastQuestId` as the upper bound
    mapping (uint32 => address) public adventureKeyQuestIds;

    /// @dev Emitted whenever an adventure key is activated or deactivated
    event AdventureKeyActivationChanged(address indexed adventureKeyAddress, uint256 questId, uint256 achievementId, bool isActive);

    constructor(address achievementsTokenAddress) {
        if(achievementsTokenAddress == address(0)) {
            revert CannotSpecifyZeroAddressForAchievementsToken();
        }

        achievementsToken = IAchievements(achievementsTokenAddress);
    }

    /// @notice Activates an adventure key for use with the Adventure Hub.
    /// Throws when the caller is not the owner of this contract.
    /// Throws when the number of previously activated adventure keys is equal to the maximum uint32 value.
    /// Throws when the specified adventure key contract does not implement the IAdventurous interface.
    /// Throws when the specified adventure key contract is already activated for use in the Adventure Hub.
    /// Throws if AdventureHub MINTER_ROLE access is revoked on the achievements contract
    ///
    /// Postconditions:
    /// The specified adventure key contract has been activated.  New entries into quests with adventure key are permitted.
    /// `adventureKeyStates` mapping has been updated.
    /// `lastQuestId` value has been incremented.
    /// An achievement id has been reserved for users that enter the quest with the activated key.
    ///
    /// @dev The metadataURI parameter has no effect for re-activations of adventure keys.
    /// If a key has already been activated, it is recommended to leave metadataURI blank.
    function activateAdventureKey(address adventureKeyAddress, string calldata metadataURI) external onlyOwner {
        if(!IERC165(adventureKeyAddress).supportsInterface(type(IAdventurous).interfaceId)) {
            revert NotAnAdventurousContract();
        }

        if(!IERC165(adventureKeyAddress).supportsInterface(type(IERC721).interfaceId)) {
            revert NotAnERC721Contract();
        }

        KeyState memory keyState = adventureKeyStates[adventureKeyAddress];

        if(keyState.questId == 0) {
            if(lastQuestId == MAX_UINT32) {
                revert NoMoreAdventureKeysCanBeActivated();
            }

            unchecked {
                uint32 questId = ++lastQuestId;
                adventureKeyStates[adventureKeyAddress].questId = questId;
                adventureKeyQuestIds[questId] = adventureKeyAddress;
            }

            adventureKeyStates[adventureKeyAddress].achievementId = achievementsToken.reserveAchievementId(metadataURI);
        } else if(keyState.isKeyActive) {
            revert AdventureKeyAlreadyActivated();
        }

        adventureKeyStates[adventureKeyAddress].isKeyActive = true;

        emit AdventureKeyActivationChanged(adventureKeyAddress, adventureKeyStates[adventureKeyAddress].questId, adventureKeyStates[adventureKeyAddress].achievementId, true);
    }

    /// @notice Deactivates an adventure key, preventing new entries into quests using the deactivated key.
    /// Players may still exit after the key is deactivated.
    /// Throws when the caller is not the owner of this contract.
    /// Throws when the adventure key address has never been activated, or is currently de-activated.
    ///
    /// Postconditions:
    /// The specified adventure key contract has been de-activated.  New entries into quests with the de-activated
    /// key will be disabled unless the key is re-activated.
    function deactivateAdventureKey(address adventureKeyAddress) external onlyOwner {
        KeyState memory keyState = adventureKeyStates[adventureKeyAddress];

        if(!keyState.isKeyActive) {
            revert AdventureKeyIsInactive();
        }

        adventureKeyStates[adventureKeyAddress].isKeyActive = false;

        emit AdventureKeyActivationChanged(adventureKeyAddress, keyState.questId, keyState.achievementId, false);
    }

    /// @notice Enters the quest associated with the specified adventure key contract for the specified token id.
    /// Throws when the owner of the adventure key is not the caller.
    /// Throws when the adventure key address has never been activated, or is currently de-activated.
    /// Throws when the AdventureHub is not currently whitelisted on the specified adventure key.
    /// Throws when the AdventureHub has not been approved by user for adventures on the specified adventure key.
    /// Throws when the specified token id on the specified adventure key is already in the quest.
    ///
    /// Postconditions:
    /// The specified token id has entered the quest associated with the specified adventure key.
    function enterQuestWithAdventureKey(address adventureKeyAddress, uint256 tokenId) external {
        _requireCallerOwnsToken(adventureKeyAddress, tokenId);

        KeyState storage keyState = adventureKeyStates[adventureKeyAddress];

        if(!keyState.isKeyActive) {
            revert AdventureKeyIsInactive();
        }

        IAdventurous(adventureKeyAddress).enterQuest(tokenId, keyState.questId);
    }

    /// @notice Exits the quest associated with the specified adventure key contract for the specified token id.
    /// Throws when the owner of the adventure key is not the caller.
    /// Throws when the adventure key address has never been activated.
    /// Throws when the AdventureHub is not currently whitelisted on the specified adventure key.
    /// Throws when the AdventureHub has not been approved by user for adventures on the specified adventure key.
    /// Throws when the specified token id on the specified adventure key is no longer in the quest.
    /// - This condition should be rare, and can only happen if the Adventure Hub is removed from the whitelist
    ///   and re-whitelisted, presenting a limited window of opportunity to backdoor userExitQuest.
    ///
    /// Postconditions:
    /// The specified token id has exited from the quest associated with the specified adventure key.
    function exitQuestWithAdventureKey(address adventureKeyAddress, uint256 tokenId) external {
        _requireCallerOwnsToken(adventureKeyAddress, tokenId);

        KeyState storage keyState = adventureKeyStates[adventureKeyAddress];

        if(keyState.questId == 0) {
            revert UnknownAdventureKey();
        }

        IAdventurous(adventureKeyAddress).exitQuest(tokenId, keyState.questId);
    }

    /// @dev Callback that mints a soulbound achievement to the adventurer that entered the quest if they haven't received the achievement previously.
    function onQuestEntered(address adventurer, uint256 /*tokenId*/, uint256 /*questId*/) external override {
        KeyState storage senderKeyState = adventureKeyStates[_msgSender()];

        if(!senderKeyState.isKeyActive) {
            revert OnQuestEnteredCallbackTriggeredByAddressThatIsNotAnActiveAdventureKey();
        }

        if(achievementsToken.balanceOf(adventurer, senderKeyState.achievementId) == 0) {
            achievementsToken.mint(adventurer, senderKeyState.achievementId, 1);
        }
    }

    /// @dev onQuestExited callback does nothing for this contract, because there is no state to synchronize
    function onQuestExited(address /*adventurer*/, uint256 /*tokenId*/, uint256 /*questId*/, uint256 /*questStartTimestamp*/) external override view {}

    /// @dev Enumerates all tokens that the specified player currently has entered into the quest.
    /// Never use this function in a transaction context - it is fine for a read-only query for 
    /// external applications, but will consume a lot of gas when used in a transaction.
    /// Throws if specified adventure key address has never been activated.
    function findQuestingTokensByAdventureKeyAndPlayer(address adventureKeyAddress, address player, uint256 tokenIdPageStart, uint256 tokenIdPageEnd) external view returns (uint256[] memory tokenIdsInQuest) {
        uint256 questId = adventureKeyStates[adventureKeyAddress].questId;

        if(questId == 0) {
            revert UnknownAdventureKey();
        }

        IAdventurousERC721 adventureKey = IAdventurousERC721(adventureKeyAddress);
        
        unchecked {
            // First, find all the token ids owned by the player
            uint256 ownerBalance = adventureKey.balanceOf(player);
            uint256[] memory ownedTokenIds = new uint256[](ownerBalance);
            uint256 tokenIndex = 0;
            for(uint256 tokenId = tokenIdPageStart; tokenId <= tokenIdPageEnd; ++tokenId) {
                try adventureKey.ownerOf(tokenId) returns (address ownerOfToken) {
                    if(ownerOfToken == player) {
                        ownedTokenIds[tokenIndex++] = tokenId;
                    }
                } catch {}
                
                if(tokenIndex == ownerBalance || tokenId == type(uint256).max) {
                    break;
                }
            }

            // For each owned token id, check the quest count
            // When 1 or greater, the spirit is engaged in a quest on this adventure.
            address thisAddress = address(this);
            uint256 numberOfTokenIdsOnQuest = 0;
            for(uint256 i = 0; i < ownerBalance; ++i) {
                uint256 ownedTokenId = ownedTokenIds[i];
                
                if(ownedTokenId > 0) {
                    (bool isPartipatingInQuest,,) = adventureKey.isParticipatingInQuest(ownedTokenId, thisAddress, questId);
                    if(isPartipatingInQuest) {
                        ++numberOfTokenIdsOnQuest;
                    }
                }
            }

            // Finally, make one more pass and populate the player quests return array
            uint256 questIndex = 0;
            tokenIdsInQuest = new uint256[](numberOfTokenIdsOnQuest);
    
            for(uint256 i = 0; i < ownerBalance; ++i) {
                uint256 ownedTokenId = ownedTokenIds[i];
                if(ownedTokenId > 0) {
                    (bool isPartipatingInQuest,,) = adventureKey.isParticipatingInQuest(ownedTokenId, thisAddress, questId);
                    if(isPartipatingInQuest) {
                        tokenIdsInQuest[questIndex] = ownedTokenId;
                        ++questIndex;
                    }
                }
    
                if(questIndex == numberOfTokenIdsOnQuest) {
                    break;
                }
            }
        }

        return tokenIdsInQuest;
    }

    /// @dev Adventure Keys are always locked/non-transferrable while they are participating in Adventure Hub quests
    function questsLockTokens() external override pure returns (bool) {
        return false;
    }

    /// @dev ERC-165 interface support
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC165, IERC165) returns (bool) {
        return interfaceId == type(IAdventure).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @dev Validates that the caller owns the specified token for the specified token contract address
    /// Throws when the caller does not own the specified token.
    function _requireCallerOwnsToken(address adventureKeyAddress, uint256 tokenId) internal view {
        if(IERC721(adventureKeyAddress).ownerOf(tokenId) != _msgSender()) {
            revert CallerNotTokenOwner();
        }
    }
}