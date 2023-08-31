// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStakefishNFTManager {
    /// @notice Withdraw from NFT - only allowed for ownerOf(tokenId)
    /// @param tokenId of the NFT
    function withdraw(uint256 tokenId) external;

    /// @notice computes address based on token
    /// @param tokenId of the NFT
    /// @return address of the validator contract
    function computeAddress(uint256 tokenId) external view returns (address);

    /// @notice lookups the NFT Owner by address => tokenId => owner
    /// @param validator address created by mint
    /// @return address of the owner
    function validatorOwner(address validator) external view returns (address);

    /// @notice lookups the tokenId based on validator address
    /// @param validator address created by mint
    /// @return tokenId of the NFT
    function tokenForValidatorAddr(address validator)
        external
        view
        returns (uint256);

    /// @notice lookups the validator address based on tokenId
    /// @param tokenId of the NFT
    /// @return address of the validator contract
    function validatorForTokenId(uint256 tokenId)
        external
        view
        returns (address);

    /// @notice claim NFT from another NFT Manager, used for migration
    /// @param oldManager old nft manager
    /// @param tokenId of the NFT on the old manager
    function claim(address oldManager, uint256 tokenId) external;

    /// @notice multicall static
    function multicallStatic(uint256[] calldata tokenIds, bytes[] calldata data)
        external
        view
        returns (bytes[] memory results);

    /// @notice multicall across multiple tokenIds
    function multicall(uint256[] calldata tokenIds, bytes[] calldata data)
        external
        returns (bytes[] memory results);
}