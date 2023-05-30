//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/// @title IVariety interface
/// @author Simon Fremaux (@dievardump)
interface IVariety is IERC721 {
    /// @notice mint `seeds.length` token(s) to `to` using `seeds`
    /// @param to token recipient
    /// @param seeds each token seed
    function plant(address to, bytes32[] memory seeds)
        external
        returns (uint256);

    /// @notice this function returns the seed associated to a tokenId
    /// @param tokenId to get the seed of
    function getTokenSeed(uint256 tokenId) external view returns (bytes32);

    /// @notice This function allows an owner to ask for a seed update
    ///         this can be needed because although I test the contract as much as possible,
    ///         it might be possible that one token does not render because the seed creates
    ///         error or even "out of gas" computation. That's why this would allow an owner
    ///         in such case, to request for a seed change that will then be triggered by Sower
    /// @param tokenId id to regenerate seed for
    function requestSeedChange(uint256 tokenId) external;

    /// @notice This function allows Sower to answer to a seed change request
    ///         in the event where a seed would produce errors of rendering
    ///         1) this function can only be called by Sower if the token owner
    ///         asked for a new seed
    ///         2) this function will only be called if there is a rendering error
    ///         or, Vitalik Buterin forbid, a duplicate
    /// @param tokenId id to regenerate seed for
    function changeSeedAfterRequest(uint256 tokenId) external;
}