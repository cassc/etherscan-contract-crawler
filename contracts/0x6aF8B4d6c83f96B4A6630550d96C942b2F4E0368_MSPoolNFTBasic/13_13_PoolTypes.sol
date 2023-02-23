// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/// @title PoolTypes Are the type of pool available in this NFT swap
/// @author JorgeLpzGnz & CarlosMario714
contract PoolTypes {

    /// @notice available pool types
    enum PoolType {
        Sell, // you can sell NFTs and get tokens
        Buy,   // you can buy NFTs with tokens
        Trade  // A pool that make both
    }
    
}