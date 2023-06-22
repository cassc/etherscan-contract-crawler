// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SharedStructs {
    struct CrowdPoolInfo {
        address payable crowdpool_owner;
        address pool_token; // the token contract address
        uint256 token_rate; // 1 ETH = token_rate of sale token
        uint256 pool_min; // min ETH pool contribution per wallet
        uint256 pool_max; // max ETH pool contribution per wallet
        uint256 hardcap; // Maximum size ETH of pool
        uint256 softcap; //Minimum size ETH of pool
        uint256 liqudity_percent; // Percentage of pool to be used for LP divided by 1000
        uint256 listing_rate; // 1 ETH = token_rate for LP start
        uint256 lock_end; // uniswap lock timestamp -> e.g. 4 weeks
        uint256 lock_start;
        uint256 crowdpool_end; // crowdpool period end
        uint256 crowdpool_start; // crowdpool period start
    }

    struct CrowdPoolLink {
        string color; //token color used in auto token creation
        string website_link; //url for the token
        string twitter_link; //twitter url for the token
        string key_val; //optional key value storage for future upgrades
        string telegram_link; //telegram url for the token
    }
}