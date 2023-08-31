// SPDX-License-Identifier: BSL-1.1

pragma solidity ^0.8.14;

interface IDarwinSwapLister {
    struct TokenInfo {
        OwnTokenomicsInfo ownToks; //? The original token's tokenomics
        TokenomicsInfo addedToks; //? Tokenomics "added" by DarwinSwap
        TokenStatus status; //? Token status
        address validator; //? If a Darwin team validator has verified this token (with whatever outcome), this is their address. Otherwise it equals the address(0)
        address owner; //? The owner of the token contract
        address feeReceiver; //? Where will the fees go
        bool valid; //? Only true if the token has been POSITIVELY validated by a Darwin team validator
        bool official; //? Only true if the token is either Darwin, WBNB, or a selected list of tokens like USDT, USDC, etc. If "official" is true, other tokens paired with this token will be able to execute tokenomics, if any
        string purpose; //? Why are you sending the fees to the feeReceiver address? Is it a treasury? Will it be used for buybacks? Marketing?
        uint unlockTime; //? Time when the tax lock will end (and taxes will be modifiable again). 0 if no lock.
    }

    struct OwnTokenomicsInfo {
        uint tokenTaxOnSell; //? The Toks 1.0 taxation applied to tokenA on sells (100%: 10000)
        uint tokenTaxOnBuy; //? The Toks 1.0 taxation applied to tokenA on buys (100%: 10000)
    }

    struct TokenomicsInfo {
        uint tokenA1TaxOnSell; //? The Toks 1.0 taxation applied to tokenA on sells (100%: 10000)
        uint tokenB1TaxOnSell; //? The Toks 1.0 taxation applied to tokenB on sells (100%: 10000)
        uint tokenA1TaxOnBuy; //? The Toks 1.0 taxation applied to tokenA on buys (100%: 10000)
        uint tokenB1TaxOnBuy; //? The Toks 1.0 taxation applied to tokenB on buys (100%: 10000)
        uint tokenA2TaxOnSell; //? The Toks 2.0 taxation applied to tokenA on sells (100%: 10000)
        uint tokenB2TaxOnSell; //? The Toks 2.0 taxation applied to tokenB on sells (100%: 10000)
        uint tokenA2TaxOnBuy; //? The Toks 2.0 taxation applied to tokenA on buys (100%: 10000)
        uint tokenB2TaxOnBuy; //? The Toks 2.0 taxation applied to tokenB on buys (100%: 10000)
        uint refundOnSell; //? Percentage (summed, not subtracted from the other toks) of Tokenomics 2.0 that will be used to refund users of own-toks-1.0 on sells
        uint refundOnBuy; //? Percentage (summed, not subtracted from the other toks) of Tokenomics 2.0 that will be used to refund users of own-toks-1.0 on buys
        uint tokenB1SellToLI; //? Percentage (summed, not subtracted from tokenB1TaxOnSell) of Tokenomics 1.0 applied to the other token that will be used, on sells, to refill the LI
        uint tokenB1BuyToLI; //? Percentage (summed, not subtracted from tokenB1TaxOnBuy) of Tokenomics 1.0 applied to the other token that will be used, on buys, to refill the LI
        uint tokenB2SellToLI; //? Percentage (summed, not subtracted from tokenB2TaxOnSell) of Tokenomics 2.0 applied to the other token that will be used, on sells, to refill the LI
        uint tokenB2BuyToLI; //? Percentage (summed, not subtracted from tokenB2TaxOnBuy) of Tokenomics 2.0 applied to the other token that will be used, on buys, to refill the LI
    }

    enum TokenStatus {
        UNLISTED, //? This token is not listed on DarwinSwap
        LISTED, //? This token has been listed on DarwinSwap
        BANNED //? This token and its owner are banned from listing on DarwinSwap (because it has been recognized as harmful during a verification)
    }

    struct Token {
        string name;
        string symbol;
        address addr;
        uint decimals;
    }

    event TokenListed(address indexed tokenAddress, TokenInfo indexed listingInfo);
    event TaxLockPeriodUpdated(address indexed tokenAddress, uint indexed newUnlockDate);
    event TokenBanned(address indexed tokenAddress, address indexed ownerAddress);

    function maxTok1Tax() external view returns (uint);
    function maxTok2Tax() external view returns (uint);

    function isValidator(address user) external view returns (bool);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function tokenInfo(address _token) external view returns(TokenInfo memory);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
}