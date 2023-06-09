// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAdventure.sol";
import "../utils/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error AdventureApprovalToCaller();
error AdventureIsStillWhitelisted();
error AlreadyWhitelisted();
error CallerNotApprovedForAdventure();
error CallerNotAWhitelistedAdventure();
error InvalidAdventureContract();
error NotWhitelisted();

/**
 * @title AdventureERC721Permissions
 * @author Limit Break, Inc.
 * @notice Implements the basic security features of the {IAdventurous} token standard for ERC721-compliant tokens.
 * This includes a whitelist for trusted Adventure contracts designed to interoperate with this token and a user
 * approval mechanism specific to {IAdventurous} functionality.
 */
abstract contract AdventurePermissions is Ownable {

    struct AdventureDetails {
        bool isWhitelisted;
        uint128 arrayIndex;
    }

    /// @dev Emitted when the adventure whitelist is updated
    event AdventureWhitelistUpdated(address indexed adventure, bool whitelisted);

    /// @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets, for special in-game adventures.
    event AdventureApprovalForAll(address indexed tokenOwner, address indexed operator, bool approved);
    
    /// @dev Whitelist array for iteration
    address[] public whitelistedAdventureList;

    /// @dev Whitelist mapping
    mapping (address => AdventureDetails) public whitelistedAdventures;

    /// @dev Mapping from owner to operator approvals for special gameplay behavior
    mapping (address => mapping (address => bool)) private _operatorAdventureApprovals;

    /// @notice Returns whether the specified account is a whitelisted adventure
    function isAdventureWhitelisted(address account) public view returns (bool) {
        return whitelistedAdventures[account].isWhitelisted;
    }

    /// @notice Whitelists an adventure and specifies whether or not the quests in that adventure lock token transfers
    /// Throws when the adventure is already in the whitelist.
    /// Throws when the specified address does not implement the IAdventure interface.
    ///
    /// Postconditions:
    /// The specified adventure contract is in the whitelist.
    /// An `AdventureWhitelistUpdate` event has been emitted.
    function whitelistAdventure(address adventure) external onlyOwner {
        if(isAdventureWhitelisted(adventure)) {
            revert AlreadyWhitelisted();
        }

        if(!IERC165(adventure).supportsInterface(type(IAdventure).interfaceId)) {
            revert InvalidAdventureContract();
        }

        whitelistedAdventures[adventure].isWhitelisted = true;
        whitelistedAdventures[adventure].arrayIndex = uint128(whitelistedAdventureList.length);
        whitelistedAdventureList.push(adventure);

        emit AdventureWhitelistUpdated(adventure, true);
    }

    /// @notice Removes an adventure from the whitelist
    /// Throws when the adventure is not in the whitelist.
    ///
    /// Postconditions:
    /// The specified adventure contract is no longer in the whitelist.
    /// An `AdventureWhitelistUpdate` event has been emitted.
    function unwhitelistAdventure(address adventure) external onlyOwner {
        if(!isAdventureWhitelisted(adventure)) {
            revert NotWhitelisted();
        }
        
        uint128 itemPositionToDelete = whitelistedAdventures[adventure].arrayIndex;
        whitelistedAdventureList[itemPositionToDelete] = whitelistedAdventureList[whitelistedAdventureList.length - 1];
        whitelistedAdventures[whitelistedAdventureList[itemPositionToDelete]].arrayIndex = itemPositionToDelete;

        whitelistedAdventureList.pop();
        delete whitelistedAdventures[adventure];

        emit AdventureWhitelistUpdated(adventure, false);
    }    

    /// @notice Similar to {IERC721-setApprovalForAll}, but for special in-game adventures only
    function setAdventuresApprovedForAll(address operator, bool approved) public {
        _setAdventuresApprovedForAll(_msgSender(), operator, approved);
    }

    /// @notice Similar to {IERC721-isApprovedForAll}, but for special in-game adventures only
    function areAdventuresApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorAdventureApprovals[owner][operator];
    }    

    /// @dev Approve `operator` to operate on all of `owner` tokens for special in-game adventures only
    function _setAdventuresApprovedForAll(address tokenOwner, address operator, bool approved) internal {
        if(tokenOwner == operator) {
            revert AdventureApprovalToCaller();
        }
        _operatorAdventureApprovals[tokenOwner][operator] = approved;
        emit AdventureApprovalForAll(tokenOwner, operator, approved);
    }

    /// Modify to remove individual approval check
    /// @dev Returns whether `spender` is allowed to manage `tokenId`, for special in-game adventures only.
    function _isApprovedForAdventure(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address tokenOwner = IERC721(address(this)).ownerOf(tokenId);
        return (areAdventuresApprovedForAll(tokenOwner, spender));
    }

    /// @dev Validates that the caller is approved for adventure on the specified token id
    /// Throws when the caller has not been approved by the user.
    function _requireCallerApprovedForAdventure(uint256 tokenId) internal view {
        if(!_isApprovedForAdventure(_msgSender(), tokenId)) {
            revert CallerNotApprovedForAdventure();
        }
    }

    /// @dev Validates that the caller is a whitelisted adventure
    /// Throws when the caller is not in the adventure whitelist.
    function _requireCallerIsWhitelistedAdventure() internal view {
        if(!isAdventureWhitelisted(_msgSender())) {
            revert CallerNotAWhitelistedAdventure();
        }
    }

    /// @dev Validates that the specified adventure has been removed from the whitelist
    /// to prevent early backdoor exiting from adventures.
    /// Throws when specified adventure is still whitelisted.
    function _requireAdventureRemovedFromWhitelist(address adventure) internal view {
        if(isAdventureWhitelisted(adventure)) {
            revert AdventureIsStillWhitelisted();
        }
    }
}