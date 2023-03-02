// SPDX-License-Identifier: Apache-2.0

/// @title Story Contract Interface
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

interface IStory {

    /// @notice event describing a creator story getting added to a token
    /// @dev this events stores creator stories on chain in the event log
    event CreatorStory(uint256 indexed tokenId, address indexed creatorAddress, string creatorName, string story);

    /// @notice event describing a collector story getting added to a token
    /// @dev this events stores collector stories on chain in the event log
    event Story(uint256 indexed tokenId, address indexed collectorAddress, string collectorName, string story);

    /// @notice function to let the creator add a story to the token they own
    /// @dev depending on the implementation, this function may be restricted in various ways, such as
    ///      limiting the number of times the creator may write a story.
    /// @dev this function MUST emit the CreatorStory event each time it is called
    /// @dev this function MUST implement logic to restrict access to only the creator
    function addCreatorStory(uint256 tokenId, string calldata creatorName, string calldata story) external;

    /// @notice function to let collectors add a story to the token they own
    /// @dev depending on the implementation, this function may be restricted in various ways, such as
    ///      limiting the number of times a collector may write a story.
    /// @dev this function MUST emit the Story event each time it is called
    /// @dev this function MUST implement logic to restrict access to only the owner of the token
    function addStory(uint256 tokenId, string calldata collectorName, string calldata story) external;
}