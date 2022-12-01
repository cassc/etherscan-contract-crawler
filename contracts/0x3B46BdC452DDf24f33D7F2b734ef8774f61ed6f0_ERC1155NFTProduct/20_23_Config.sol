// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Config {
    /// Fixed at deployment time
    struct Deployment {
        // Name of the NFT contract.
        string name;
        // Symbol of the NFT contract.
        string symbol;
        // The contract owner address. If you wish to own the contract, then set it as your wallet address.
        // This is also the wallet that can manage the contract on NFT marketplaces.
        address owner;
        // If true, tokens may be burned by owner. Cannot be changed later.
        bool tokensBurnable;
    }

    /// Updatable by admins and owner
    struct Runtime {
        // Metadata base URI for tokens, NFTs minted in this contract will have metadata URI of `baseURI` + `tokenID`.
        // Set this to reveal token metadata.
        string baseURI;
        // If true, the base URI of the NFTs minted in the specified contract can be updated after minting (token URIs
        // are not frozen on the contract level). This is useful for revealing NFTs after the drop. If false, all the
        // NFTs minted in this contract are frozen by default which means token URIs are non-updatable.
        bool metadataUpdatable;
        // If true, tokens may be transferred by owner. Default is true. Can be only changed to false.
        bool tokensTransferable;
        // Secondary market royalties in basis points (100 bps = 1%)
        uint256 royaltiesBps;
        // Address for royalties
        address royaltiesAddress;
    }
}