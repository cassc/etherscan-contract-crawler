// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IAdventureApproval.sol";
import "./IMintablePotion.sol";
import "./IMinterWhitelist.sol";
import "./DarkSpiritCustodian.sol";
import "limit-break-contracts/contracts/adventures/IAdventure.sol";
import "limit-break-contracts/contracts/adventures/IAdventurousERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

error CallbackNotImplemented();
error CallerDidNotCreateClaimId();
error CallerNotOwnerOfDarkSpirit();
error CallerNotOwnerOfDarkHeroSpirit();
error CannotExceedOneThousandQueriesPerCall();
error CannotSpecifyZeroAddressForDarkSpiritsContract();
error CannotSpecifyZeroAddressForDarkHeroSpiritsContract();
error CannotSpecifyZeroAddressForVillainPotionContract();
error CannotSpecifyZeroAddressForSuperVillainPotionContract();
error ClaimIdOverflow();
error CompleteQuestToRedeemPotion();
error InputArrayLengthMismatch();
error MustIncludeAtLeastOneSpirit();
error NoPotionQuestFoundForSpecifiedClaimId();
error QuantityMustBeGreaterThanZero();
error QuestCompletePotionMustBeRedeemed();

/**
 * @title PotionCraftingAdventure
 * @author Limit Break, Inc.
 * @notice An adventure that burns crafted spirits into potions.
 */
contract PotionCraftingAdventure is Ownable, Pausable, ERC165, IAdventure {

    struct PotionQuest {
        uint64 startTimestamp;
        uint16 darkSpiritTokenId;
        uint16 darkHeroSpiritTokenId;
        address adventurer;
    }

    /// @dev The amount of time the user must remain in the quest to complete it and receive a hero
    uint256 public constant CRAFTING_DURATION = 7 days;

    /// @dev An unchangeable reference to the villain potion contract that is rewarded at the conclusion of adventure quest if a single dark spirit was used
    IMintablePotion immutable public villainPotionContract;

    /// @dev An unchangeable reference to the super villain potion contract that is rewarded at the conclusion of adventure quest if two dark spirits were used
    IMintablePotion immutable public superVillainPotionContract;

    /// @dev An unchangeable reference to the dark spirit token contract
    IAdventurousERC721 immutable public darkSpiritsContract;

    /// @dev An unchangeable reference to the dark hero spirit token contract
    IAdventurousERC721 immutable public darkHeroSpiritsContract;

    /// @dev An unchangeable reference to a custodial holding contract for dark spirits
    DarkSpiritCustodian immutable public custodian;

    /// @dev A counter for claim ids
    uint256 public lastClaimId;

    /// @dev Map claim id to potion quest details
    mapping (uint256 => PotionQuest) public potionQuestLookup;

    /// @dev Emitted when an adventurer abandons/cancels a potion currently being crafted
    event AbandonedPotion(address indexed adventurer, uint256 indexed claimId);

    /// @dev Emitted when an adventurer starts crafting a potion
    event CraftingPotion(address indexed adventurer, uint256 indexed claimId, uint256 darkSpiritTokenId, uint256 darkHeroSpiritTokenId);

    /// @dev Emitted when an adventurer redeems a crafted a potion
    event CraftedPotion(address indexed adventurer, uint256 indexed claimId);

    /// @dev Specify the potion, dark spririt, and dark hero spirit token contract addresses during creation
    constructor(address villainPotionAddress, address superVillainPotionAddress, address darkSpiritsAddress, address darkHeroSpiritsAddress) {
        if(villainPotionAddress == address(0)) {
            revert CannotSpecifyZeroAddressForVillainPotionContract();
        }

        if(superVillainPotionAddress == address(0)) {
            revert CannotSpecifyZeroAddressForSuperVillainPotionContract();
        }

        if(darkSpiritsAddress == address(0)) {
            revert CannotSpecifyZeroAddressForDarkSpiritsContract();
        }

        if(darkHeroSpiritsAddress == address(0)) {
            revert CannotSpecifyZeroAddressForDarkHeroSpiritsContract();
        }

        villainPotionContract = IMintablePotion(villainPotionAddress);
        superVillainPotionContract = IMintablePotion(superVillainPotionAddress);
        darkSpiritsContract = IAdventurousERC721(darkSpiritsAddress);
        darkHeroSpiritsContract = IAdventurousERC721(darkHeroSpiritsAddress);

        custodian = new DarkSpiritCustodian(address(this), darkSpiritsAddress, darkHeroSpiritsAddress);
    }

    /// @dev ERC-165 interface support
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC165, IERC165) returns (bool) {
        return interfaceId == type(IAdventure).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @dev A callback function that AdventureERC721 must invoke when a quest has been successfully entered.
    /// Throws in all cases quest entry for this adventure is fulfilled via adventureTransferFrom instead of enterQuest, and this callback should not be triggered.
    function onQuestEntered(address /*adventurer*/, uint256 /*tokenId*/, uint256 /*questId*/) external override pure {
        revert CallbackNotImplemented();
    }

    /// @dev A callback function that AdventureERC721 must invoke when a quest has been successfully entered.
    /// Throws in all cases quest exit for this adventure is fulfilled via transferFrom or adventureBurn instead of exitQuest, and this callback should not be triggered.
    function onQuestExited(address /*adventurer*/, uint256 /*tokenId*/, uint256 /*questId*/, uint256 /*questStartTimestamp*/) external override pure {
        revert CallbackNotImplemented();
    }

    /// @dev Returns false - spirits are transferred into this contract for crafting
    function questsLockTokens() external override pure returns (bool) {
        return false;
    }

    /// @dev Pauses and blocks adventurers from starting new potion crafting quests
    /// Throws if the adventure is already paused
    function pauseNewQuestEntries() external onlyOwner {
        _pause();
    }

    /// @dev Unpauses and allows adventurers to start new potion crafting quests
    /// Throws if the adventure is already unpaused
    function unpauseNewQuestEntries() external onlyOwner {
        _unpause();
    }

    /// @notice Enters the potion crafting quests with a batch of specified dark spirits and dark hero spirits.
    /// Dark spirit token ids may be 0, in which case it means no dark spirit will be included in the potion.
    /// Dark hero spirit token ids may be 0, in which case it means no dark hero spirit will be included in the potion.
    ///
    /// Throws when `quantity` is zero, where `quantity` is the length of the token id arrays.
    /// Throws when token id array lengths don't match.
    /// Throws when the caller does not own a specified dark spirit token.
    /// Throws when the caller does not own a specified dark hero spirit token.
    /// Throws when neither a dark spirit or dark hero spirit token are specified (0 values for both ids at the same array index).
    /// Throws when adventureTransferFrom throws, typically for one of the following reasons:
    ///   - This adventure contract is not in the adventure whitelist for dark spirit or dark hero spirit contract.
    ///   - The caller has not set adventure approval for this contract.
    /// /// Throws when the contract is paused
    ///
    /// Postconditions:
    /// ---------------
    /// The specified dark spirits are now owned by this contract.
    /// The specified dark hero spirits are now owned by this contract.
    /// The value of the lastClaimId counter has increased by `quantity`, where `quantity` is the length of the token id arrays.
    /// The potion quest lookup for the newly created claim ids contains the following information:
    ///   - The block timestamp of this transaction (the time at which crafting the potion began).
    ///   - The specified dark spirit token id.
    ///   - The specified dark hero spirit token id.
    ///   - The address of the adventurer that is permitted to retrieve their spirits or redeem their potion.
    /// `quantity` CraftingPotion events have been emitted, where `quantity` is the length of the token id arrays.
    function startCraftingPotionsBatch(uint256[] calldata darkSpiritTokenIds, uint256[] calldata darkHeroSpiritTokenIds) external whenNotPaused {
        if(darkSpiritTokenIds.length == 0) {
            revert QuantityMustBeGreaterThanZero();
        }

        if(darkHeroSpiritTokenIds.length != darkSpiritTokenIds.length) {
            revert InputArrayLengthMismatch();
        }

        uint256 claimId;
        unchecked {
            claimId = lastClaimId;
            lastClaimId = claimId + darkSpiritTokenIds.length;
            ++claimId;
        }

        for(uint256 i = 0; i < darkSpiritTokenIds.length;) {
            _startCraftingPotion(claimId + i, darkSpiritTokenIds[i], darkHeroSpiritTokenIds[i]);
            
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Abandons multiple potion crafting quests referenced by the specifed claim ids before the required crafting duration has been met.
    ///
    /// Throws when `quantity` is zero, where `quantity` is the length of the claim id arrays.
    /// Throws when no potion quest is found for one or more of the specified claim ids (start timestamp is zero).
    /// Throws when the caller did not create one or more of the specified claim id (adventurer not the same as caller).
    /// Throws when the one or more of the potions are ready to redeem (required crafting duration has been met or exceeded).
    ///
    /// Postconditions:
    /// ---------------
    /// The dark spirit and/or dark hero spirit that were in use to craft the potions have been returned to the adventurer that started crafting with them.
    /// The potion quest lookup entry for the specified claim ids have been removed.
    /// `quantity` AbandonedPotion events have been emitted, where `quantity` is the length of the claim id array.
    function abandonPotionsBatch(uint256[] calldata claimIds) external {
        if(claimIds.length == 0) {
            revert QuantityMustBeGreaterThanZero();
        }

        for(uint256 i = 0; i < claimIds.length;) {
            _abandonPotion(claimIds[i]);
            
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Redeems multiple crafted potions referenced by the specifed claim ids after the required crafting duration has been met.
    ///
    /// Throws when `quantity` is zero, where `quantity` is the length of the claim id arrays.
    /// Throws when no potion quest is found for one or more of the specified claim ids (start timestamp is zero).
    /// Throws when the caller did not create one or more of the specified claim ids (adventurer not the same as caller).
    /// Throws when one or more of the potions is not ready to redeem (required crafting duration has not been met).
    ///
    /// Postconditions:
    /// ---------------
    /// The dark spirit and/or dark hero spirit that were in use to craft a potion have been burned.
    /// The potion quest lookup entry for the specified claim id has been removed.
    /// A potion has been minted to the adventurer who crafted the potion.
    /// `quantity` CraftedPotion events have been emitted, where `quantity` is the length of the claim id arrays.
    function redeemPotionsBatch(uint256[] calldata claimIds) external {
        if(claimIds.length == 0) {
            revert QuantityMustBeGreaterThanZero();
        }

        uint256[] memory darkSpiritTokenIds = new uint256[](claimIds.length);
        uint256[] memory darkHeroSpiritTokenIds = new uint256[](claimIds.length);

        uint256 numVillainPotions = 0;
        uint256 numSuperVillainPotions = 0;

        for(uint256 i = 0; i < claimIds.length;) {
            (uint256 darkSpiritTokenId, uint256 darkHeroSpiritTokenId) = _redeemPotion(claimIds[i]);
            darkSpiritTokenIds[i] = darkSpiritTokenId;
            darkHeroSpiritTokenIds[i] = darkHeroSpiritTokenId;
            
            unchecked {
                ++i;

                if(darkSpiritTokenId == 0 || darkHeroSpiritTokenId == 0) {
                    ++numVillainPotions;
                } else {
                    ++numSuperVillainPotions;
                }
            }
        }

        uint256[] memory villainDarkSpiritTokenIds = new uint256[](numVillainPotions);
        uint256[] memory villainDarkHeroSpiritTokenIds = new uint256[](numVillainPotions);

        uint256[] memory superVillainDarkSpiritTokenIds = new uint256[](numSuperVillainPotions);
        uint256[] memory superVillainDarkHeroSpiritTokenIds = new uint256[](numSuperVillainPotions);

        uint256 villainPotionCounter = 0;
        uint256 superVillainPotionCounter = 0;

        unchecked {
            for(uint256 i = 0; i < claimIds.length; ++i) {
                uint256 darkSpiritTokenId = darkSpiritTokenIds[i];
                uint256 darkHeroSpiritTokenId = darkHeroSpiritTokenIds[i];
    
                if(darkSpiritTokenId == 0 || darkHeroSpiritTokenId == 0) {
                    villainDarkSpiritTokenIds[villainPotionCounter] = darkSpiritTokenId;
                    villainDarkHeroSpiritTokenIds[villainPotionCounter] = darkHeroSpiritTokenId;
                    ++villainPotionCounter;
                } else {
                    superVillainDarkSpiritTokenIds[superVillainPotionCounter] = darkSpiritTokenId;
                    superVillainDarkHeroSpiritTokenIds[superVillainPotionCounter] = darkHeroSpiritTokenId;
                    ++superVillainPotionCounter;
                }
            }
        }

        if(numVillainPotions > 0) {
            villainPotionContract.mintPotionsBatch(_msgSender(), villainDarkSpiritTokenIds, villainDarkHeroSpiritTokenIds);
        }

        if(numSuperVillainPotions > 0) {
            superVillainPotionContract.mintPotionsBatch(_msgSender(), superVillainDarkSpiritTokenIds, superVillainDarkHeroSpiritTokenIds);
        }
    }

    /// @dev Enumerates all specified claim ids and returns the potion quest details for each.
    /// Never use this function in a transaction context - it is fine for a read-only query for 
    /// external applications, but will consume a lot of gas when used in a transaction.
    function getPotionQuestDetailsBatch(uint256[] calldata claimIds) external view returns (PotionQuest[] memory potionQuests) {
        potionQuests = new PotionQuest[](claimIds.length);
        unchecked {
             for(uint256 i = 0; i < claimIds.length; ++i) {
                 potionQuests[i] = potionQuestLookup[claimIds[i]];
             }
        }

        return potionQuests;
    }

    /// @dev Records details of a potion quests with the specified claim id and transfers 
    /// specified dark spirit and dark hero spirit tokens to the contract.
    ///
    /// Throws when the caller does not own the specified dark spirit token.
    /// Throws when the caller does not own the specified dark hero spirit token.
    /// Throws when neither a dark spirit or dark hero spirit token are specified (0 values for both ids).
    /// Throws when adventureTransferFrom throws, typically for one of the following reasons:
    ///   - This adventure contract is not in the adventure whitelist for dark spirit or dark hero spirit contract.
    ///   - The caller has not set adventure approval for this contract.
    ///
    /// Postconditions:
    /// ---------------
    /// The specified dark spirit is now owned by this contract.
    /// The specified dark hero spirit is now owned by this contract.
    /// The potion quest lookup for the specified created claim id contains the following information:
    ///   - The block timestamp of this transaction (the time at which crafting the potion began).
    ///   - The specified dark spirit token id.
    ///   - The specified dark hero spirit token id.
    ///   - The address of the adventurer that is permitted to retrieve their spirits or redeem their potion.
    /// A CraftingPotion event has been emitted.
    function _startCraftingPotion(uint256 claimId, uint256 darkSpiritTokenId, uint256 darkHeroSpiritTokenId) private {
        if(darkSpiritTokenId == 0 && darkHeroSpiritTokenId == 0) {
            revert MustIncludeAtLeastOneSpirit();
        }

        address caller = _msgSender();

        potionQuestLookup[claimId].startTimestamp = uint64(block.timestamp);
        potionQuestLookup[claimId].darkSpiritTokenId = uint16(darkSpiritTokenId);
        potionQuestLookup[claimId].darkHeroSpiritTokenId = uint16(darkHeroSpiritTokenId);
        potionQuestLookup[claimId].adventurer = caller;

        emit CraftingPotion(caller, claimId, darkSpiritTokenId, darkHeroSpiritTokenId);

        if(darkSpiritTokenId > 0) {
            address darkSpiritTokenOwner = darkSpiritsContract.ownerOf(darkSpiritTokenId);
            if(darkSpiritTokenOwner != caller) {
                revert CallerNotOwnerOfDarkSpirit();
            }

            darkSpiritsContract.adventureTransferFrom(darkSpiritTokenOwner, address(custodian), darkSpiritTokenId);
        }

        if(darkHeroSpiritTokenId > 0) {
            address darkHeroSpiritTokenOwner = darkHeroSpiritsContract.ownerOf(darkHeroSpiritTokenId);
            if(darkHeroSpiritTokenOwner != caller) {
                revert CallerNotOwnerOfDarkHeroSpirit();
            }

            darkHeroSpiritsContract.adventureTransferFrom(darkHeroSpiritTokenOwner, address(custodian), darkHeroSpiritTokenId);
        }
    }

    /// @dev Abandons the potion crafting quest referenced by the claim id before the required crafting duration has been met.
    ///
    /// Throws when no potion quest is found for the specified claim id (start timestamp is zero).
    /// Throws when the caller did not create the specified claim id (adventurer not the same as caller).
    /// Throws when the potion is ready to redeem (required crafting duration has been met or exceeded).
    ///  - One exception to this rule is if the potion crafting adventure is removed from the whitelist of either dark spirit contract.
    ///    In that case, the user can abandon the potion to recover their dark spirits since redemption is not possible.
    ///
    /// Postconditions:
    /// ---------------
    /// The dark spirit and/or dark hero spirit that were in use to craft a potion have been returned to the adventurer that started crafting with them.
    /// The potion quest lookup entry for the specified claim id has been removed.
    /// An AbandonedPotion event has been emitted.
    function _abandonPotion(uint256 claimId) private {
        (address adventurer, uint256 darkSpiritTokenId, uint256 darkHeroSpiritTokenId, bool questCompleted) = _getAndClearPotionQuestStatus(claimId);

        bool allowUserToAbandonQuestsAfterQuestCompleted = false;
        if(!IAdventureApproval(address(darkSpiritsContract)).isAdventureWhitelisted(address(this)) || 
           !IAdventureApproval(address(darkHeroSpiritsContract)).isAdventureWhitelisted(address(this)) ||
           !IMinterWhitelist(address(villainPotionContract)).whitelistedMinters(address(this)) ||
           !IMinterWhitelist(address(superVillainPotionContract)).whitelistedMinters(address(this))) {
          allowUserToAbandonQuestsAfterQuestCompleted = true;
        }

        if(questCompleted && !allowUserToAbandonQuestsAfterQuestCompleted) {
            revert QuestCompletePotionMustBeRedeemed();
        }

        emit AbandonedPotion(adventurer, claimId);

        if(darkSpiritTokenId > 0) {
            darkSpiritsContract.transferFrom(address(custodian), adventurer, darkSpiritTokenId);
        }

        if(darkHeroSpiritTokenId > 0) {
            darkHeroSpiritsContract.transferFrom(address(custodian), adventurer, darkHeroSpiritTokenId);
        }
    }

    /// @dev Redeems a crafted potion referenced by the claim id after the required crafting duration has been met.
    ///
    /// Throws when no potion quest is found for the specified claim id (start timestamp is zero).
    /// Throws when the caller did not create the specified claim id (adventurer not the same as caller).
    /// Throws when the potion is not ready to redeem (required crafting duration has not been met).
    ///
    /// Postconditions:
    /// ---------------
    /// The dark spirit and/or dark hero spirit that were in use to craft a potion have been burned.
    /// The potion quest lookup entry for the specified claim id has been removed.
    /// A potion has been minted to the adventurer who crafted the potion.
    /// A CraftedPotion event has been emitted.
    function _redeemPotion(uint256 claimId) private returns (uint256, uint256) {
        (address adventurer, uint256 darkSpiritTokenId, uint256 darkHeroSpiritTokenId, bool questCompleted) = _getAndClearPotionQuestStatus(claimId);

        if(!questCompleted) {
            revert CompleteQuestToRedeemPotion();
        }

        emit CraftedPotion(adventurer, claimId);

        if(darkSpiritTokenId > 0) {
            darkSpiritsContract.adventureBurn(darkSpiritTokenId);
        }

        if(darkHeroSpiritTokenId > 0) {
            darkHeroSpiritsContract.adventureBurn(darkHeroSpiritTokenId);
        }

        return (darkSpiritTokenId, darkHeroSpiritTokenId);
    }

    /// @dev Returns potion quest details by claim id and removes the potion quest lookup entry.
    ///
    /// Throws when no potion quest is found for the specified claim id (start timestamp is zero).
    /// Throws when the caller did not create the specified claim id (adventurer not the same as caller).
    function _getAndClearPotionQuestStatus(uint256 claimId) private returns (address adventurer, uint256 darkSpiritTokenId, uint256 darkHeroSpiritTokenId, bool questCompleted) {
        PotionQuest memory potionQuest = potionQuestLookup[claimId];

        uint256 startTimestamp = potionQuest.startTimestamp;
        adventurer = potionQuest.adventurer;
        darkSpiritTokenId = potionQuest.darkSpiritTokenId;
        darkHeroSpiritTokenId = potionQuest.darkHeroSpiritTokenId;

        if(startTimestamp == 0) {
            revert NoPotionQuestFoundForSpecifiedClaimId();
        }

        if(adventurer != _msgSender()) {
            revert CallerDidNotCreateClaimId();
        }

        unchecked {
            questCompleted = block.timestamp - startTimestamp >= CRAFTING_DURATION;
        }

        delete potionQuestLookup[claimId];

        return (adventurer, darkSpiritTokenId, darkHeroSpiritTokenId, questCompleted);
    }
}