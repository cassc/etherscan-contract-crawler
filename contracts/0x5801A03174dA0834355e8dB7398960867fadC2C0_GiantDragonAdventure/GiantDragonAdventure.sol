/**
 *Submitted for verification at Etherscan.io on 2023-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IAdventureApproval {
    function setAdventuresApprovedForAll(address operator, bool approved) external;
    function areAdventuresApprovedForAll(address owner, address operator) external view returns (bool);
    function isAdventureWhitelisted(address account) external view returns (bool);
}

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract DragonCustodian {
    constructor(address babyDragons, address dragonEssence, address dragonAdventure) {
        IERC721(dragonEssence).setApprovalForAll(dragonAdventure, true);
        IERC721(babyDragons).setApprovalForAll(dragonAdventure, true);
        IAdventureApproval(dragonEssence).setAdventuresApprovedForAll(dragonAdventure, true);
        IAdventureApproval(babyDragons).setAdventuresApprovedForAll(dragonAdventure, true);
    }
}

/**
 * @dev Required interface of mintable Giant Dragon contracts.
 */
interface IMintableGiantDragon {
    /**
     * @notice Mints multiple Giant Dragons evolved with the specified Baby Dragon and Dragon Essence tokens.
     */
    function mintDragonsBatch(
        address to,
        uint256[] calldata babyDragonTokenIds,
        uint256[] calldata dragonEssenceTokenIds
    ) external;
}

/**
 * @dev Required interface to determine if a minter is whitelisted
 */
interface IMinterWhitelist {
    /**
     * @notice Determines if an address is a whitelisted minter
     */
    function whitelistedMinters(address account) external view returns (bool);
}

/**
 * @title IAdventure
 * @author Limit Break, Inc.
 * @notice The base interface that all `Adventure` contracts must conform to.
 * @dev All contracts that implement the adventure/quest system and interact with an {IAdventurous} token are required to implement this interface.
 */
interface IAdventure is IERC165 {

    /**
     * @dev Returns whether or not quests on this adventure lock tokens.
     * Developers of adventure contract should ensure that this is immutable 
     * after deployment of the adventure contract.  Failure to do so
     * can lead to error that deadlock token transfers.
     */
    function questsLockTokens() external view returns (bool);

    /**
     * @dev A callback function that AdventureERC721 must invoke when a quest has been successfully entered.
     * Throws if the caller is not an expected AdventureERC721 contract designed to work with the Adventure.
     * Not permitted to throw in any other case, as this could lead to tokens being locked in quests.
     */
    function onQuestEntered(address adventurer, uint256 tokenId, uint256 questId) external;

    /**
     * @dev A callback function that AdventureERC721 must invoke when a quest has been successfully exited.
     * Throws if the caller is not an expected AdventureERC721 contract designed to work with the Adventure.
     * Not permitted to throw in any other case, as this could lead to tokens being locked in quests.
     */
    function onQuestExited(address adventurer, uint256 tokenId, uint256 questId, uint256 questStartTimestamp) external;
}

/**
 * @title Quest
 * @author Limit Break, Inc.
 * @notice Quest data structure for {IAdventurous} contracts.
 */
struct Quest {
    bool isActive;
    uint32 questId;
    uint64 startTimestamp;
    uint32 arrayIndex;
}

/**
 * @title IAdventurous
 * @author Limit Break, Inc.
 * @notice The base interface that all `Adventurous` token contracts must conform to in order to support adventures and quests.
 * @dev All contracts that support adventures and quests are required to implement this interface.
 */
interface IAdventurous is IERC165 {

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets, for special in-game adventures.
     */ 
    event AdventureApprovalForAll(address indexed tokenOwner, address indexed operator, bool approved);

    /**
     * @dev Emitted when a token enters or exits a quest
     */
    event QuestUpdated(uint256 indexed tokenId, address indexed tokenOwner, address indexed adventure, uint256 questId, bool active, bool booted);

    /**
     * @notice Transfers a player's token if they have opted into an authorized, whitelisted adventure.
     */
    function adventureTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @notice Safe transfers a player's token if they have opted into an authorized, whitelisted adventure.
     */
    function adventureSafeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @notice Burns a player's token if they have opted into an authorized, whitelisted adventure.
     */
    function adventureBurn(uint256 tokenId) external;

    /**
     * @notice Enters a player's token into a quest if they have opted into an authorized, whitelisted adventure.
     */
    function enterQuest(uint256 tokenId, uint256 questId) external;

    /**
     * @notice Exits a player's token from a quest if they have opted into an authorized, whitelisted adventure.
     */
    function exitQuest(uint256 tokenId, uint256 questId) external;

    /**
     * @notice Returns the number of quests a token is actively participating in for a specified adventure
     */
    function getQuestCount(uint256 tokenId, address adventure) external view returns (uint256);

    /**
     * @notice Returns the amount of time a token has been participating in the specified quest
     */
    function getTimeOnQuest(uint256 tokenId, address adventure, uint256 questId) external view returns (uint256);

    /**
     * @notice Returns whether or not a token is currently participating in the specified quest as well as the time it was started and the quest index
     */
    function isParticipatingInQuest(uint256 tokenId, address adventure, uint256 questId) external view returns (bool participatingInQuest, uint256 startTimestamp, uint256 index);

    /**
     * @notice Returns a list of all active quests for the specified token id and adventure
     */
    function getActiveQuests(uint256 tokenId, address adventure) external view returns (Quest[] memory activeQuests);
}

/**
 * @title IAdventurousERC721
 * @author Limit Break, Inc.
 * @notice Combines all {IAdventurous} and all {IERC721} functionality into a single, unified interface.
 * @dev This interface may be used as a convenience to interact with tokens that support both interface standards.
 */
interface IAdventurousERC721 is IERC721, IAdventurous {

}

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @title GiantDragonAdventure
 * @author Limit Break, Inc.
 * @notice An adventure that combines your Baby Dragon and a provided Dragon Essence.
 */
contract GiantDragonAdventure is Ownable, Pausable, ERC165, IAdventure {
    error GiantDragonAdventure__CallbackNotImplemented();
    error GiantDragonAdventure__CallerNotOwnerOfBabyDragon();
    error GiantDragonAdventure__CallerNotOwnerOfDragonEssence();
    error GiantDragonAdventure__CannotSpecifyAddressZeroForBabyDragons();
    error GiantDragonAdventure__CannotSpecifyAddressZeroForGiantDragon();
    error GiantDragonAdventure__CannotSpecifyAddressZeroForDragonEssence();
    error GiantDragonAdventure__InputArrayLengthMismatch();
    error GiantDragonAdventure__QuantityMustBeGreaterThanZero();

    /// @dev An unchangeable reference to the Baby Dragons contract used in the dragon quest.
    IAdventurousERC721 public immutable babyDragons;

    /// @dev An unchangeable reference to the Dragon Essence contract used in the dragon quest.
    IAdventurousERC721 public immutable dragonEssence;

    /// @dev An unchangeable reference to the Giant Dragons contract given at the end of the quest.
    IMintableGiantDragon public immutable giantDragons;

    constructor(address babyDragonAddress, address dragonEssenceAddress, address giantDragonAddress) {
        if (babyDragonAddress == address(0)) {
            revert GiantDragonAdventure__CannotSpecifyAddressZeroForBabyDragons();
        }
        if (dragonEssenceAddress == address(0)) {
            revert GiantDragonAdventure__CannotSpecifyAddressZeroForDragonEssence();
        }
        if (giantDragonAddress == address(0)) {
            revert GiantDragonAdventure__CannotSpecifyAddressZeroForGiantDragon();
        }

        babyDragons = IAdventurousERC721(babyDragonAddress);
        dragonEssence = IAdventurousERC721(dragonEssenceAddress);
        giantDragons = IMintableGiantDragon(giantDragonAddress);
    }

    /// @dev A callback function that AdventureERC721 must invoke when a quest has been successfully entered.
    /// Throws in all cases quest entry for this adventure is fulfilled via adventureTransferFrom instead of onQuestEntered, and this callback should not be triggered.
    function onQuestEntered(address, /*adventurer*/ uint256, /*tokenId*/ uint256 /*questId*/ ) external pure override {
        revert GiantDragonAdventure__CallbackNotImplemented();
    }

    /// @dev A callback function that AdventureERC721 must invoke when a quest has been successfully exited.
    /// Throws in all cases quest exit for this adventure is fulfilled via transferFrom or adventureBurn instead of onQuestExited, and this callback should not be triggered.
    function onQuestExited(
        address, /*adventurer*/
        uint256, /*tokenId*/
        uint256, /*questId*/
        uint256 /*questStartTimestamp*/
    ) external pure override {
        revert GiantDragonAdventure__CallbackNotImplemented();
    }

    /// @notice Returns false - this quest uses hard staking.
    function questsLockTokens() external pure override returns (bool) {
        return false;
    }

    /**
     * @notice Pauses new quest entries for the quest.
     *
     * @dev    Throws if the caller is not the owner.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. `_pause` is set to true.
     */
    function pauseNewQuestEntries() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses new quest entries for the quest.
     *
     * @dev    Throws if the caller is not the owner.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. `_pause` is set to false.
     */
    function unpauseNewQuestEntries() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Combines the provided Baby Dragons and Dragon Essences to form Giant Dragons
     *
     * @dev    Throws when `quantity` is zero, where `quantity` is the length of the Baby Dragons Token IDs array.
     * @dev    Throws when the lengths of the Baby Dragon Token IDs and Dragon Essence Token IDs do not match.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The Baby Dragons used to complete the quest have been burnt.
     * @dev    2. The Dragon Essences used to complete the quest have been burnt.
     * @dev    3. A Giant Dragon has been minted to the adventurer who has completed the quest.
     * @dev    4. `quantity` DragonMinted events are emitted, where `quantity` is the length of the provided Baby Dragon token IDs.
     *
     * @param babyDragonTokenIds    Array of token IDs to enter the quest with.
     * @param dragonEssenceTokenIds Array of token IDs to combine with Baby Dragons.
     */
    function combineDragonsWithEssences(uint256[] calldata babyDragonTokenIds, uint256[] calldata dragonEssenceTokenIds) external {
        _requireNotPaused();

        if (babyDragonTokenIds.length != dragonEssenceTokenIds.length) {
            revert GiantDragonAdventure__InputArrayLengthMismatch();
        }
        
        if (babyDragonTokenIds.length == 0) {
            revert GiantDragonAdventure__QuantityMustBeGreaterThanZero();
        }

        for (uint256 i = 0; i < babyDragonTokenIds.length;) {
            uint256 babyDragonTokenId = babyDragonTokenIds[i];
            uint256 dragonEssenceTokenId = dragonEssenceTokenIds[i];

            if (babyDragons.ownerOf(babyDragonTokenId) != _msgSender()) {
                revert GiantDragonAdventure__CallerNotOwnerOfBabyDragon();
            }

            if (dragonEssence.ownerOf(dragonEssenceTokenId) != _msgSender()) {
                revert GiantDragonAdventure__CallerNotOwnerOfDragonEssence();
            }

            babyDragons.adventureBurn(babyDragonTokenId);
            dragonEssence.adventureBurn(dragonEssenceTokenId);
            unchecked {
                ++i;
            }
        }

        giantDragons.mintDragonsBatch(_msgSender(), babyDragonTokenIds, dragonEssenceTokenIds);
    }

    /// @notice ERC-165 interface support
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IAdventure).interfaceId || super.supportsInterface(interfaceId);
    }
}