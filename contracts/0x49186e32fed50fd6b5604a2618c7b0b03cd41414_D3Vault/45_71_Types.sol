// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

library Types {
    struct D3MMState {
        // the D3vault contract
        address _D3_VAULT_;
        // the creator of pool
        address _CREATOR_;
        // maker contract address
        address _MAKER_;
        address _ORACLE_;
        address _FEE_RATE_MODEL_;
        address _MAINTAINER_;
        // token balance
        mapping(address => uint256) balances;
        // the tokens have been deposited into pool
        address[] depositedTokenList;
        // record if a token has been deposited before
        mapping(address => bool) hasDepositedToken;
    }

    struct TokenCumulative {
        uint256 cumulativeAsk;
        uint256 cumulativeBid;
    }

    struct TokenMMInfo {
        // ask price with decimal
        uint256 askDownPrice;
        uint256 askUpPrice;
        // bid price with decimal
        uint256 bidDownPrice;
        uint256 bidUpPrice;
        uint256 askAmount;
        uint256 bidAmount;
        // k, unit is 1e18
        uint256 kAsk;
        uint256 kBid;
        // cumulative
        uint256 cumulativeAsk;
        uint256 cumulativeBid;
        // swap fee, unit is 1e18
        uint256 swapFeeRate;
        uint256 mtFeeRate;
    }

    struct RangeOrderState {
        address oracle;
        TokenMMInfo fromTokenMMInfo;
        TokenMMInfo toTokenMMInfo;
    }

    function parseRealAmount(uint256 realAmount, uint256 tokenDec) internal pure returns(uint256 amountWithDec18) {
        if(tokenDec < 18) {
            uint256 fixDec = 18 - tokenDec;
            amountWithDec18 = realAmount * (10 ** fixDec);
        } else if(tokenDec == 18) {
            amountWithDec18 = realAmount;
        } else {
            uint256 fixDec = tokenDec - 18;
            amountWithDec18 = realAmount / (10 ** fixDec);
        }
    }

    function parseDec18Amount(uint256 amountWithDec18, uint256 tokenDec) internal pure returns(uint256 realAmount) {
        if(tokenDec < 18) {
            uint256 fixDec = 18 - tokenDec;
            realAmount = amountWithDec18 / (10 ** fixDec);
        } else if(tokenDec == 18) {
            realAmount = amountWithDec18;
        } else {
            uint256 fixDec = tokenDec - 18;
            realAmount = amountWithDec18 * (10 ** fixDec);
        }
    }
}