// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "witnet-solidity-bridge/contracts/requests/WitnetRequest.sol";
import "./interfaces/IWittyPixelsTokenVault.sol";

/// @title  WittyPixels - Library containing both ERC721 and ERC20 data models
/// @author Otherplane Labs Ltd., 2023

library WittyPixels {

    /// ===============================================================================================================
    /// --- WITTYPIXELS DATA MODEL ------------------------------------------------------------------------------------
    
    bytes32 internal constant WPX_TOKEN_SLOTHASH =
        /* keccak256("art.wittypixels.token") */
        0xa1c65a69721a75d8ec79c686c8573bd06e7f0c400997cbe153064301cbc480d5;
    
    bytes32 internal constant WPX_TOKEN_VAULT_SLOTHASH =
        /* keccak256("art.wittypixels.token.vault") */
        0x3c39a4bcf91d618a40909e659271a0d850789843a1b2ede0bffa31cd98ff6976;

    struct TokenInitParams {
        string baseURI;
        string name;
        string symbol;
    }

    struct TokenStorage {
        // --- ERC721
        string  baseURI;
        uint256 totalSupply;
        mapping (uint256 => ERC721Token) items;
        
        // --- ITokenVaultFactory
        IWittyPixelsTokenVault tokenVaultPrototype;
        uint256 totalTokenVaults;
        mapping (uint256 => IWittyPixelsTokenVault) vaults;

        // --- WittyPixelsToken
        WitnetRequest imageDigestRequest;
        WitnetRequest tokenStatsRequest;
        mapping (uint256 => ERC721TokenWitnetQueries) tokenWitnetQueries;
        mapping (uint256 => ERC721TokenWitnetRequests) tokenWitnetRequests;
    }

    enum ERC721TokenStatus {
        Void,
        Launching,
        Minting,
        Fractionalized,
        Acquired
    }

    struct ERC721Token {
        string  baseURI;
        uint256 birthTs;        
        string  imageDigest;
        bytes32 imageDigestWitnetTxHash;         
        bytes32 tokenStatsWitnetRadHash;
        ERC721TokenEvent theEvent;
        ERC721TokenStats theStats;
        ERC721TokenCharity theCharity;
    }
    
    struct ERC721TokenEvent {
        string  name;
        string  venue;
        string  whereabouts;
        uint256 startTs;
        uint256 endTs;
    }

    struct ERC721TokenStats {
        uint256 canvasHeight;
        uint256 canvasPixels;
        bytes32 canvasRoot;
        uint256 canvasWidth;
        uint256 totalPixels;
        uint256 totalPlayers;
        uint256 totalScans;
    }

    struct ERC721TokenCharity {
        string  description;
        uint8   percentage; 
        address wallet;
    }
    
    struct ERC721TokenWitnetQueries {
        uint256 imageDigestId;
        uint256 tokenStatsId;
    }

    struct ERC721TokenWitnetRequests {
        WitnetRequest imageDigest;
        WitnetRequest tokenStats;
    }

    struct TokenVaultOwnershipDeeds {
        address parentToken;
        uint256 parentTokenId;
        address playerAddress;
        uint256 playerIndex;
        uint256 playerPixels;
        bytes32[] playerPixelsProof;
        bytes signature;
    }

    struct TokenVaultInitParams {
        address curator;
        string  name;
        bytes   settings;
        string  symbol;
        address token;
        uint256 tokenId;
        uint256 tokenPixels;
    }

    struct TokenVaultStorage {
        // --- IERC1633
        address parentToken;
        uint256 parentTokenId;

        // --- IWittyPixelsTokenVault
        address curator;
        uint256 finalPrice;
        
        ITokenVaultAuctionDutch.Settings settings;
        IWittyPixelsTokenVault.Stats stats;
        
        address[] authors;
        mapping (address => uint256) legacyPixels;
        mapping (address => bool) redeemed;
        mapping (uint256 => TokenVaultPlayerInfo) players;

        TokenVaultCharity charity;
    }

    struct TokenVaultPlayerInfo {
        address addr;
        uint256 pixels;
    }

    struct TokenVaultCharity {
        uint8 percentage;
        address wallet;
    }

}