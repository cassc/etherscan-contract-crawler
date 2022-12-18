// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title An interface for a contract that is capable of deploying derivative nft license contract
/// @notice A contract that constructs a contract must implement this to pass arguments to the contract
/// @dev This is used to avoid having constructor arguments in the contract, which results in the init code hash
/// of the pool being constant allowing the CREATE2 address of the pool to be cheaply computed on-chain
interface IVanillaDNFTDeployer {
    /// @notice Get the parameters to be used in constructing the pool, set transiently during contract creation.
    /// @dev Called by the pool constructor to fetch the parameters of the contract
    /// Returns factory The factory address
    /// Returns originalNFT The NFT address
    /// Returns tokenId The token of the nft address
    function parameters()
        external
        view
        returns (address factory, address originalNFT, uint256 tokenId);

    function deploy(
        address factory,
        address originalNFT,
        uint256 tokenId,
        address spanningLabDelegate
    ) external returns (address licenseAddress);
}