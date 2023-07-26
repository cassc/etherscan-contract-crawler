// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IHibernationDen {
    /// @notice the lone sleepooor (single NFT)
    struct SleepingNFT {
        /// @dev address of the ERC721/ERC1155
        address tokenAddress;
        /// @dev tokenID of the sleeping NFT
        uint256 tokenId;
        /// @dev true if the tokenAddress points to an ERC1155
        bool isERC1155;
    }

    struct FermentedJar {
        /// @dev id of the fermented jar
        uint256 id;
        /// @dev boolean to determine if the user has awoken the sleeping NFT
        bool isUsed;
    }

    /// @notice The bundle Config (Collection)
    struct SlumberParty {
        /// @dev unique ID representing the bundle
        uint8 bundleId;
        /// @dev the block.timestamp when the mint() function can be called. Should be set at game-start and is used as a proxy to determine if a game has started
        uint256 publicMintTime;
        /// @dev chainId that can wakeSleeper
        uint256 assetChainId;
        /// @dev The chainId that can mint
        uint256 mintChainId;
        /// @dev Used so a tokenID 0 can't wake the slumberParty before special Honeyjar is found.
        bool fermentedJarsFound;
        /// @dev used to track the number of used fermentedJars
        uint256 numUsed;
        /// @dev list of jars that have a claim on the sleeping NFTs
        FermentedJar[] fermentedJars;
        /// @dev list of sleeping NFTs
        SleepingNFT[] sleepoors;
        /// @dev the jar numbers that will cause parties to be fermented. The last index is the maximum number of honeyjars allowed to be minted
        /// @dev the gap between checkpoints MUST be big enough so that a user can't mint through multiple checkpoints.
        uint256[] checkpoints;
        /// @dev index tracker for which checkpoint we're part of.
        uint256 checkpointIndex;
    }

    function startGame(uint256 srcChainId, uint8 bundleId_, uint256 numSleepers_, uint256[] calldata checkpoints)
        external;
    function setCrossChainFermentedJars(uint8 bundleId, uint256[] calldata fermentedJarIds) external;

    function getSlumberParty(uint8 bundleId) external returns (SlumberParty memory);
}