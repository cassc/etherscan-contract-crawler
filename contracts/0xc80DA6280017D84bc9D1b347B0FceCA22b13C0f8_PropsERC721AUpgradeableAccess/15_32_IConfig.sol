// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: @props

/**
 * @dev
 */
interface IConfig {

    /**
    * @dev Retool that - legacy
    */
    // enum Extensions {
    //     Allowlist,
    //     Royalty,
    //     Split
    // }

    /**
    * @dev
    */
    struct Config {
        Mint mintConfig;
        Token tokenConfig;
    }

    /**
    * @dev
    */
    struct Mint {
        bool isActive;
        uint256 startTime;
        uint256 endTime;
        uint256 maxSupply;
        uint256 maxPerWallet;
        uint256 maxPerTxn;
        uint256 price;
    }

    /**
    * @dev
    */
    struct Token {
        string metadataUri;
    }


    /**
    * @dev
    */
    struct Token1155 {
        uint256 tokenId;
        uint256 redeemStart;
        uint256 redeemEnd;
        uint256[] tokensToIssueOnRedeem;
        bool isRedeemable;
        string baseURI;
        string name;
    }

}