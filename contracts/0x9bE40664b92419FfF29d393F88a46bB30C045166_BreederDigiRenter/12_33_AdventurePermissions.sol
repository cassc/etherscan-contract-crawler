// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract AdventurePermissions is Ownable {
    struct AdventureDetails {
        bool isWhitelisted;
        bool questsLockTokens;
        uint128 arrayIndex;
    }

    /// @dev Emitted when the adventure whitelist is updated
    event AdventureWhitelistUpdated(address indexed adventure, bool whitelisted);

    /// @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets, for special in-game adventures.
    event AdventureApprovalForAll(
        address indexed tokenOwner,
        address indexed operator,
        bool approved
    );

    /// @dev Whitelist array for iteration
    address[] public whitelistedAdventureList;

    /// @dev Whitelist mapping
    mapping(address => AdventureDetails) public whitelistedAdventures;

    /// @dev Mapping from owner to operator approvals for special gameplay behavior
    mapping(address => mapping(address => bool)) private
        _operatorAdventureApprovals;

    modifier onlyAdventure() {
        require(isAdventureWhitelisted(_msgSender()), "Not an adventure.");
        _;
    }

    /// @notice Returns whether the specified account is a whitelisted adventure
    function isAdventureWhitelisted(address account)
        public
        view
        returns (bool)
    {
        return whitelistedAdventures[account].isWhitelisted;
    }

    /// @notice Whitelists an adventure and specifies whether or not the quests in that adventure lock token transfers
    function whitelistAdventure(address adventure, bool questsLockTokens)
        external
        onlyOwner
    {
        require(!whitelistedAdventures[adventure].isWhitelisted, "Already whitelisted");
        whitelistedAdventures[adventure].isWhitelisted = true;
        whitelistedAdventures[adventure].questsLockTokens = questsLockTokens;
        whitelistedAdventures[adventure].arrayIndex =
            uint128(whitelistedAdventureList.length);
        whitelistedAdventureList.push(adventure);

        emit AdventureWhitelistUpdated(adventure, true);
    }

    /// @notice Removes an adventure from the whitelist
    function unwhitelistAdventure(address adventure) external onlyOwner {
        require(whitelistedAdventures[adventure].isWhitelisted, "Not whitelisted");

        uint128 itemPositionToDelete =
            whitelistedAdventures[adventure].arrayIndex;
        whitelistedAdventureList[itemPositionToDelete] =
            whitelistedAdventureList[whitelistedAdventureList.length - 1];
        whitelistedAdventures[whitelistedAdventureList[itemPositionToDelete]]
        .arrayIndex = itemPositionToDelete;

        whitelistedAdventureList.pop();
        delete whitelistedAdventures[adventure];

        emit AdventureWhitelistUpdated(adventure, false);
    }

    /// @notice Similar to {IERC721-setApprovalForAll}, but for special in-game adventures only
    function setAdventuresApprovedForAll(address operator, bool approved)
        public
    {
        _setAdventuresApprovedForAll(_msgSender(), operator, approved);
    }

    /// @notice Similar to {IERC721-isApprovedForAll}, but for special in-game adventures only
    function areAdventuresApprovedForAll(address owner, address operator)
        public
        view
        returns (bool)
    {
        return _operatorAdventureApprovals[owner][operator];
    }

    /// @dev Approve `operator` to operate on all of `owner` tokens for special in-game adventures only
    function _setAdventuresApprovedForAll(
        address tokenOwner,
        address operator,
        bool approved
    )
        internal
    {
        require(tokenOwner != operator, "approve to caller");
        _operatorAdventureApprovals[tokenOwner][operator] = approved;
        emit AdventureApprovalForAll(tokenOwner, operator, approved);
    }

    /// Modify to remove individual approval check
    /// @dev Returns whether `spender` is allowed to manage `tokenId`, for special in-game adventures only.
    function _isApprovedForAdventure(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        address tokenOwner = IERC721(address(this)).ownerOf(tokenId);
        return (areAdventuresApprovedForAll(tokenOwner, spender));
    }
}