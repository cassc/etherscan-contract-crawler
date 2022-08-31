//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library Types {


    struct V3Fees {
        //token to take fees with
        IERC20 feeToken;

        //affiliate to pay portion of fees to
        address affiliate;

        //portion of fees that goes to affiliate
        uint affiliatePortion;

        //the current eth price of the fee token. Only used if 
        //txn fails to compute gas fee
        uint feeTokenETHPrice;

        //amount of fee token to take as the dexible fee
        uint dexibleFee;

        //pre-determined gas fee for the txn
        uint gasFee;
    }

    struct V3Order {
        //trader that owns the order
        address trader;

        //token being offered
        TokenAmount input;

        //token wanted
        TokenAmount output;

        //fee information
        V3Fees fees;
    }

    struct TokenAmount {
        IERC20 token;
        uint112 amount;
    }

    //status of order. Only tracked on action from user/miners
    enum OrderStatus {
        UNDEFINED,
        PENDING,
        FILLED,
        CANCELLED,
        PENALIZED
    }

    struct Order {

        //trader that owns the order
        address trader;

        //the token we are taking as fee
        IERC20 feeToken;

        //eth price of fee token in 18-decimal units
        uint feeTokenETHPrice;

        //current price of ETH in USD units
        uint ethUSDPrice;

        //an estimate of gas to use to fill the order
        uint gasEstimate;

        //token being offered
        TokenAmount input;

        //token wanted
        TokenAmount output;
    }

    //============== CONFIG STATE =============/
    struct Config {
        //dev team address (120b)
        address devTeam;

        //bps fee expressed as a whole number
        uint128 minFee;

        //penalty a user faces for removing assets or 
        //allowances before a trade
        uint128 penaltyFee;

        //number of blocks to lock stake and order cancellations
        uint8 lockoutBlocks;
    }

    //============== ACCESS STATE =============/
    //storage structure of access controls
    struct AccessControl {
        bool reentrantFlag;
        mapping(bytes32 => mapping(address => bool)) roles;
    }

    //============== INITIALIZATION STATE =============/
    struct InitControls {
        bool initialized;
        bool initializing;
    }
}