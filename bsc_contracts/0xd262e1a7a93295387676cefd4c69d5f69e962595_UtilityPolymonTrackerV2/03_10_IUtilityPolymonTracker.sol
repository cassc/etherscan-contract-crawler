// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUtilityPolymonTracker {
    struct SoftMintedData {
        // @dev id of the soft minted token
        uint256 id;
        // @dev first id from the booster opening
        uint256 first;
        // @dev last id from the booster opening
        uint256 last;
    }

    struct SoftMintedDataOld {
        // @dev id of the soft minted token
        uint256 id;
        // @dev all ids from booster opening
        uint256[] ids;
    }

    /// @notice get owner status for multiple tokens. If the owner of any of these tokens does not match the owner
    /// passed to this function the result is false.
    function isOwner(
        address owner,
        SoftMintedData[] memory softMinted,
        SoftMintedDataOld[] memory softMintedOld,
        uint256[] memory hardMinted
    ) external view returns (bool);

    /// @notice get owner status from the opener contract (only for soft minted tokens)
    function isOwnerSoftMinted(address owner, SoftMintedData memory data) external view returns (bool);

    /// @notice get owner status from the soft minter contract (only for old soft minted tokens on ethereum)
    function isOwnerSoftMintedOld(address owner, SoftMintedDataOld memory data) external view returns (bool);

    /// @notice get owner status from the ERC721 contract (only for hard minted tokens)
    function isOwnerHardMinted(address owner, uint256 nftId) external view returns (bool);

    function burnToken(
        address owner,
        uint256 nftId,
        bool hardminted
    ) external;

    function burnedTokens(uint256 nftId) external view returns (bool);
}