// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {ERC165Upgradeable} from "openzeppelin-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {
    IStory, StoryNotEnabled, TokenDoesNotExist, NotTokenOwner, NotTokenCreator, NotStoryAdmin
} from "../IStory.sol";

/*//////////////////////////////////////////////////////////////////////////
                            Story Contract
//////////////////////////////////////////////////////////////////////////*/

/// @title Story Contract
/// @dev upgradeable, inheritable abstract contract implementing the Story Contract interface
/// @author transientlabs.xyz
/// @custom:version 3.0.0
abstract contract StoryContractUpgradeable is Initializable, IStory, ERC165Upgradeable {
    /*//////////////////////////////////////////////////////////////////////////
                                State Variables
    //////////////////////////////////////////////////////////////////////////*/

    bool public storyEnabled;

    /*//////////////////////////////////////////////////////////////////////////
                                Modifiers
    //////////////////////////////////////////////////////////////////////////*/

    modifier storyMustBeEnabled() {
        if (!storyEnabled) revert StoryNotEnabled();
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Initializer
    //////////////////////////////////////////////////////////////////////////*/

    /// @param enabled - a bool to enable or disable Story addition
    function __StoryContractUpgradeable_init(bool enabled) internal {
        __StoryContractUpgradeable_init_unchained(enabled);
    }

    /// @param enabled - a bool to enable or disable Story addition
    function __StoryContractUpgradeable_init_unchained(bool enabled) internal {
        storyEnabled = enabled;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Story Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev function to set story enabled/disabled
    /// @dev requires story admin
    /// @param enabled - a boolean setting to enable or disable Story additions
    function setStoryEnabled(bool enabled) external {
        if (!_isStoryAdmin(msg.sender)) revert NotStoryAdmin();
        storyEnabled = enabled;
    }

    /// @inheritdoc IStory
    function addCreatorStory(uint256 tokenId, string calldata creatorName, string calldata story)
        external
        storyMustBeEnabled
    {
        if (!_tokenExists(tokenId)) revert TokenDoesNotExist();
        if (!_isCreator(msg.sender, tokenId)) revert NotTokenCreator();

        emit CreatorStory(tokenId, msg.sender, creatorName, story);
    }

    /// @inheritdoc IStory
    function addStory(uint256 tokenId, string calldata collectorName, string calldata story)
        external
        storyMustBeEnabled
    {
        if (!_tokenExists(tokenId)) revert TokenDoesNotExist();
        if (!_isTokenOwner(msg.sender, tokenId)) revert NotTokenOwner();

        emit Story(tokenId, msg.sender, collectorName, story);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Hooks
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev function to allow access to enabling/disabling story
    /// @param potentialAdmin - the address to check for admin priviledges
    function _isStoryAdmin(address potentialAdmin) internal view virtual returns (bool);

    /// @dev function to check if a token exists on the token contract
    /// @param tokenId - the token id to check for existence
    function _tokenExists(uint256 tokenId) internal view virtual returns (bool);

    /// @dev function to check ownership of a token
    /// @param potentialOwner - the address to check for ownership of `tokenId`
    /// @param tokenId - the token id to check ownership against
    function _isTokenOwner(address potentialOwner, uint256 tokenId) internal view virtual returns (bool);

    /// @dev function to check creatorship of a token
    /// @param potentialCreator - the address to check creatorship of `tokenId`
    /// @param tokenId - the token id to check creatorship against
    function _isCreator(address potentialCreator, uint256 tokenId) internal view virtual returns (bool);

    /*//////////////////////////////////////////////////////////////////////////
                                Overrides
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IStory).interfaceId || ERC165Upgradeable.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Upgradeability Gap
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev gap variable - see https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[50] private _gap;
}