// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IEstateStaking is IERC721Receiver {
    struct StakedToken {
        address user;
        uint64 timeStaked;
    }

    /// @notice Emits when a user stakes their NFT.
    /// @param owner the wallet address of the owner of the NFT being staked.
    /// @param tokenId the tokenId of the Estates NFT being staked.
    event StartStake(address indexed owner, uint64 tokenId);

    /// @notice Emits when a user unstakes their NFT.
    /// @param owner the wallet address of the owner of the NFT being unstaked.
    /// @param tokenId the tokenId of the Estates NFT being unstaked.
    /// @param duration the duration the NFT was staked for.
    event Unstake(
        address indexed owner,
        uint64 tokenId,
        uint64 duration
    );

    /// @notice Retrieves a user's NFT from the staking contract
    /// @param tokenId the tokenId of the staked NFT
    function singleUnstake(uint64 tokenId) external;

    /// @notice Unstakes serveral of a user's NFTs
    /// @param tokenIds the tokenId of the NFT to be staked
    function groupUnstake(uint64[] memory tokenIds) external;
}