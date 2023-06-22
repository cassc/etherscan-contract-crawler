// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SharedStructs {
    struct PresaleInfo {
        address payable presale_owner;
        address sale_token; // sale token
        uint256 token_rate; // 1 base token = ? s_tokens, fixed price
        uint256 raise_min; // maximum base token BUY amount per buyer
        uint256 raise_max; // the amount of presale tokens up for presale
        uint256 hardcap; // Maximum riase amount
        uint256 softcap; //Minimum raise amount
        uint256 liqudity_percent; // divided by 1000
        uint256 listing_rate; // fixed rate at which the token will list on uniswap
        uint256 lock_end; // uniswap lock timestamp -> e.g. 2 weeks
        uint256 lock_start;
        uint256 presale_end; // presale period
        uint256 presale_start; // presale start
    }

    struct PresaleLink {
        string website_link;
        string github_link;
        string twitter_link;
        string reddit_link;
        string telegram_link;
    }
}