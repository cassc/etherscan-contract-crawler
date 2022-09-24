// SPDX-License-Identifer: MIT

/// @title Hidden Stories by Michelle Viljoen
/// @author transientlabs.xyz

pragma solidity 0.8.14;

import "ERC721ATLCore.sol";

contract HiddenStories is ERC721ATLCore {

    struct TokenDetails {
        address prevStoryContributor;
        uint256 numStories;
    }

    bool private _hasMinted;
    uint256 private _numToMint;
    mapping(uint256 => TokenDetails) private _tokenDetails;

    event StoryAdded(uint256 indexed tokenId, address indexed writer, string name, string story);

    constructor(
        address royaltyRecipient,
        uint256 royaltyPercentage,
        address admin,
        address payout,
        uint256 numToMint
    )
        ERC721ATLCore(
            "Hidden Stories, Chapter One - Sight of Hand",
            "HIDDEN_STORIES",
            royaltyRecipient,
            royaltyPercentage,
            numToMint,
            admin,
            payout
        )
    {
        _numToMint = numToMint;
    }

    /// @notice function to mint the pieces to the owner wallet
    /// @dev requires admin or owner
    function mint() external adminOrOwner {
        require(!_hasMinted, "HiddenStories: All the pieces have already been minted!");
        _hasMinted = true;
        _mint(owner(), _numToMint);
    }

    /// @notice function for artist to set initial stories
    /// @dev requires admin or owner
    /// @dev numStories for each token must be 0
    /// @param tokenId is the token id to set the story for
    /// @param story is the story to add
    function addArtistStory(uint256 tokenId, string memory story) external adminOrOwner {
        require(_tokenDetails[tokenId].numStories == 0, "HiddenStories: token already has a story!");
        _tokenDetails[tokenId].numStories++;
        emit StoryAdded(tokenId, owner(), "Michelle Viljoen", story);
    }

    /// @notice function to add story for a token
    /// @dev requires msg.sender to be the owner of the token
    /// @dev the owner of the token can only write a story once so they must make it worth it
    /// @param tokenId is the token id to link the story to
    /// @param name is the name of the sender (optional)
    /// @param story is the story to write
    function addStory(uint256 tokenId, string memory name, string memory story) external {
        require(ownerOf(tokenId) == msg.sender, "HiddenStories: sender must be the owner of the token");
        require(_tokenDetails[tokenId].prevStoryContributor != msg.sender, "HiddenStories: sender has already recorded a story"); // on transfer this gets reset to the zero address
        _tokenDetails[tokenId].prevStoryContributor = msg.sender;
        _tokenDetails[tokenId].numStories++;
        emit StoryAdded(tokenId, msg.sender, name, story);
    }

    /// @notice function to see how many stories have been added based on tokenId
    /// @param tokenId is the tokenId to query for
    /// @return num is the number of stories
    function getNumStories(uint256 tokenId) external view returns (uint256 num) {
        require(_exists(tokenId), "HiddenStories: query for non-existent token");
        return(_tokenDetails[tokenId].numStories);
    }

    /// @notice function to get the last story contributor for a token
    function getLastContributor(uint256 tokenId) external view returns (address) {
        require(_exists(tokenId), "HiddenStories: query for non-existent token");
        return(_tokenDetails[tokenId].prevStoryContributor);
    }

    /// @notice function to override ERC721A function
    /// @dev resets prevStoryContributor for the tokens
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    )
        internal
        override
    {
        if (from != address(0)) {
            for (uint256 i = startTokenId; i < startTokenId + quantity; i++) {
                delete _tokenDetails[i].prevStoryContributor;
            }
        }
    }
    
}