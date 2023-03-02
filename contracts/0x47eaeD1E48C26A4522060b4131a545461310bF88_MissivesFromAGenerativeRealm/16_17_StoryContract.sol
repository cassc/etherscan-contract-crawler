// SPDX-License-Identifier: Apache-2.0

/// @title Story Contract
/// @author transientlabs.xyz

/**
    ____        _ __    __   ____  _ ________                     __ 
   / __ )__  __(_) /___/ /  / __ \(_) __/ __/__  ________  ____  / /_
  / __  / / / / / / __  /  / / / / / /_/ /_/ _ \/ ___/ _ \/ __ \/ __/
 / /_/ / /_/ / / / /_/ /  / /_/ / / __/ __/  __/ /  /  __/ / / / /_  
/_____/\__,_/_/_/\__,_/  /_____/_/_/ /_/  \___/_/   \___/_/ /_/\__/  
                                                                     
  ______                      _            __     __          __        
 /_  __/________ _____  _____(_)__  ____  / /_   / /   ____ _/ /_  _____
  / / / ___/ __ `/ __ \/ ___/ / _ \/ __ \/ __/  / /   / __ `/ __ \/ ___/
 / / / /  / /_/ / / / (__  ) /  __/ / / / /_   / /___/ /_/ / /_/ (__  ) 
/_/ /_/   \__,_/_/ /_/____/_/\___/_/ /_/\__/  /_____/\__,_/_.___/____/  
                                                                        
*/

pragma solidity 0.8.17;

import "IStory.sol";
import "ERC165.sol";

abstract contract StoryContract is IStory, ERC165 {

    //================= State Variables =================//
    bool public storyEnabled;

    //================= Constructor =================//
    /// @param enabled is a bool to enable or disable Story addition. This cannot be undone later.
    constructor(bool enabled) {
        storyEnabled = enabled;
    }

    //================= IStory Functions =================//
    /// @dev see {IStory.addCreatorStory}
    function addCreatorStory(uint256 tokenId, string calldata creatorName, string calldata story) external {
        require(storyEnabled, "StoryContract: story addition is not enabled");
        require(_tokenExists(tokenId), "StoryContract: token does not exist");
        emit CreatorStory(tokenId, msg.sender, creatorName, story);
    }

    /// @dev see {IStory.addStory}
    function addStory(uint256 tokenId, string calldata collectorName, string calldata story) external {
        require(storyEnabled, "StoryContract: story addition is not enabled");
        require(_isTokenOwner(msg.sender, tokenId), "StoryContract: caller is not token owner");
        emit Story(tokenId, msg.sender, collectorName, story);
    }

    //================= Internal Functions To Override By Inheriting Contract =================//
    /// @notice function to check if a token exists on the token contract
    function _tokenExists(uint256 tokenId) internal view virtual returns (bool);

    /// @notice function to check ownership of a token
    function _isTokenOwner(address potentialOwner, uint256 tokenId) internal view virtual returns (bool);

    //================= ERC165 =================//
    /// @dev see {ERC165.supportsInterface}
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IStory).interfaceId || ERC165.supportsInterface(interfaceId);
    }
}