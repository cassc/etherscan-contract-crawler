// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/**
 * @title Errors library
 * @author BendDao; Forked and edited by Unlockd
 * @notice Defines the error messages emitted by the different contracts of the Unlockd protocol
 */
library Errors {
  enum ReturnCode {
    SUCCESS,
    FAILED
  }

  string public constant SUCCESS = "0";

  //common errors
  string public constant CALLER_NOT_POOL_ADMIN = "100"; // 'The caller must be the pool admin'
  string public constant CALLER_NOT_ADDRESS_PROVIDER = "101";
  string public constant INVALID_FROM_BALANCE_AFTER_TRANSFER = "102";
  string public constant INVALID_TO_BALANCE_AFTER_TRANSFER = "103";
  string public constant CALLER_NOT_ONBEHALFOF_OR_IN_WHITELIST = "104";
  string public constant CALLER_NOT_POOL_LIQUIDATOR = "105";
  string public constant INVALID_ZERO_ADDRESS = "106";
  string public constant CALLER_NOT_LTV_MANAGER = "107";
  string public constant CALLER_NOT_PRICE_MANAGER = "108";
  string public constant CALLER_NOT_UTOKEN_MANAGER = "109";

  //math library errors
  string public constant MATH_MULTIPLICATION_OVERFLOW = "200";
  string public constant MATH_ADDITION_OVERFLOW = "201";
  string public constant MATH_DIVISION_BY_ZERO = "202";

  //validation & check errors
  string public constant VL_INVALID_AMOUNT = "301"; // 'Amount must be greater than 0'
  string public constant VL_NO_ACTIVE_RESERVE = "302"; // 'Action requires an active reserve'
  string public constant VL_RESERVE_FROZEN = "303"; // 'Action cannot be performed because the reserve is frozen'
  string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = "304"; // 'User cannot withdraw more than the available balance'
  string public constant VL_BORROWING_NOT_ENABLED = "305"; // 'Borrowing is not enabled'
  string public constant VL_COLLATERAL_BALANCE_IS_0 = "306"; // 'The collateral balance is 0'
  string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = "307"; // 'Health factor is lesser than the liquidation threshold'
  string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = "308"; // 'There is not enough collateral to cover a new borrow'
  string public constant VL_NO_DEBT_OF_SELECTED_TYPE = "309"; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
  string public constant VL_NO_ACTIVE_NFT = "310";
  string public constant VL_NFT_FROZEN = "311";
  string public constant VL_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "312"; // 'User did not borrow the specified currency'
  string public constant VL_INVALID_HEALTH_FACTOR = "313";
  string public constant VL_INVALID_ONBEHALFOF_ADDRESS = "314";
  string public constant VL_INVALID_TARGET_ADDRESS = "315";
  string public constant VL_INVALID_RESERVE_ADDRESS = "316";
  string public constant VL_SPECIFIED_LOAN_NOT_BORROWED_BY_USER = "317";
  string public constant VL_SPECIFIED_RESERVE_NOT_BORROWED_BY_USER = "318";
  string public constant VL_HEALTH_FACTOR_HIGHER_THAN_LIQUIDATION_THRESHOLD = "319";
  string public constant VL_TIMEFRAME_EXCEEDED = "320";
  string public constant VL_VALUE_EXCEED_TREASURY_BALANCE = "321";

  //lend pool errors
  string public constant LP_CALLER_NOT_LEND_POOL_CONFIGURATOR = "400"; // 'The caller of the function is not the lending pool configurator'
  string public constant LP_IS_PAUSED = "401"; // 'Pool is paused'
  string public constant LP_NO_MORE_RESERVES_ALLOWED = "402";
  string public constant LP_NOT_CONTRACT = "403";
  string public constant LP_BORROW_NOT_EXCEED_LIQUIDATION_THRESHOLD = "404";
  string public constant LP_BORROW_IS_EXCEED_LIQUIDATION_PRICE = "405";
  string public constant LP_NO_MORE_NFTS_ALLOWED = "406";
  string public constant LP_INVALID_USER_NFT_AMOUNT = "407";
  string public constant LP_INCONSISTENT_PARAMS = "408";
  string public constant LP_NFT_IS_NOT_USED_AS_COLLATERAL = "409";
  string public constant LP_CALLER_MUST_BE_AN_UTOKEN = "410";
  string public constant LP_INVALID_NFT_AMOUNT = "411";
  string public constant LP_NFT_HAS_USED_AS_COLLATERAL = "412";
  string public constant LP_DELEGATE_CALL_FAILED = "413";
  string public constant LP_AMOUNT_LESS_THAN_EXTRA_DEBT = "414";
  string public constant LP_AMOUNT_LESS_THAN_REDEEM_THRESHOLD = "415";
  string public constant LP_AMOUNT_GREATER_THAN_MAX_REPAY = "416";
  string public constant LP_NFT_TOKEN_ID_EXCEED_MAX_LIMIT = "417";
  string public constant LP_NFT_SUPPLY_NUM_EXCEED_MAX_LIMIT = "418";
  string public constant LP_CALLER_NOT_LEND_POOL_LIQUIDATOR_NOR_GATEWAY = "419";
  string public constant LP_CONSECUTIVE_BIDS_NOT_ALLOWED = "420";
  string public constant LP_INVALID_OVERFLOW_VALUE = "421";
  string public constant LP_CALLER_NOT_NFT_HOLDER = "422";
  string public constant LP_NFT_NOT_ALLOWED_TO_SELL = "423";
  string public constant LP_RESERVES_WITHOUT_ENOUGH_LIQUIDITY = "424";
  string public constant LP_COLLECTION_NOT_SUPPORTED = "425";
  string public constant LP_MSG_VALUE_DIFFERENT_FROM_CONFIG_FEE = "426";
  string public constant LP_INVALID_SAFE_HEALTH_FACTOR = "427";
  string public constant LP_AMOUNT_LESS_THAN_DEBT = "428";
  string public constant LP_AMOUNT_DIFFERENT_FROM_REQUIRED_BUYOUT_PRICE = "429";
  string public constant LP_CALLER_NOT_DEBT_TOKEN_MANAGER = "430";
  string public constant LP_CALLER_NOT_RESERVOIR_OR_DEBT_MARKET = "431";
  string public constant LP_AMOUNT_LESS_THAN_BUYOUT_PRICE = "432";

  //lend pool loan errors
  string public constant LPL_CLAIM_HASNT_STARTED_YET = "479";
  string public constant LPL_INVALID_LOAN_STATE = "480";
  string public constant LPL_INVALID_LOAN_AMOUNT = "481";
  string public constant LPL_INVALID_TAKEN_AMOUNT = "482";
  string public constant LPL_AMOUNT_OVERFLOW = "483";
  string public constant LPL_BID_PRICE_LESS_THAN_DEBT_PRICE = "484";
  string public constant LPL_BID_PRICE_LESS_THAN_HIGHEST_PRICE = "485";
  string public constant LPL_BID_REDEEM_DURATION_HAS_END = "486";
  string public constant LPL_BID_USER_NOT_SAME = "487";
  string public constant LPL_BID_REPAY_AMOUNT_NOT_ENOUGH = "488";
  string public constant LPL_BID_AUCTION_DURATION_HAS_END = "489";
  string public constant LPL_BID_AUCTION_DURATION_NOT_END = "490";
  string public constant LPL_BID_PRICE_LESS_THAN_BORROW = "491";
  string public constant LPL_INVALID_BIDDER_ADDRESS = "492";
  string public constant LPL_AMOUNT_LESS_THAN_BID_FINE = "493";
  string public constant LPL_INVALID_BID_FINE = "494";
  string public constant LPL_BID_PRICE_LESS_THAN_MIN_BID_REQUIRED = "495";
  string public constant LPL_BID_NOT_BUYOUT_PRICE = "496";
  string public constant LPL_BUYOUT_DURATION_HAS_END = "497";
  string public constant LPL_BUYOUT_PRICE_LESS_THAN_BORROW = "498";
  string public constant LPL_CALLER_MUST_BE_MARKET_ADAPTER = "499";

  //common token errors
  string public constant CT_CALLER_MUST_BE_LEND_POOL = "500"; // 'The caller of this function must be a lending pool'
  string public constant CT_INVALID_MINT_AMOUNT = "501"; //invalid amount to mint
  string public constant CT_INVALID_BURN_AMOUNT = "502"; //invalid amount to burn
  string public constant CT_BORROW_ALLOWANCE_NOT_ENOUGH = "503";
  string public constant CT_CALLER_MUST_BE_DEBT_MARKET = "504"; // 'The caller of this function must be a debt market'

  //reserve logic errors
  string public constant RL_RESERVE_ALREADY_INITIALIZED = "601"; // 'Reserve has already been initialized'
  string public constant RL_LIQUIDITY_INDEX_OVERFLOW = "602"; //  Liquidity index overflows uint128
  string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = "603"; //  Variable borrow index overflows uint128
  string public constant RL_LIQUIDITY_RATE_OVERFLOW = "604"; //  Liquidity rate overflows uint128
  string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = "605"; //  Variable borrow rate overflows uint128

  //configure errors
  string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = "700"; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_CONFIGURATION = "701"; // 'Invalid risk parameters for the reserve'
  string public constant LPC_CALLER_NOT_EMERGENCY_ADMIN = "702"; // 'The caller must be the emergency admin'
  string public constant LPC_INVALID_UNFT_ADDRESS = "703";
  string public constant LPC_INVALIED_LOAN_ADDRESS = "704";
  string public constant LPC_NFT_LIQUIDITY_NOT_0 = "705";
  string public constant LPC_PARAMS_MISMATCH = "706"; // NFT assets & token ids mismatch
  string public constant LPC_FEE_PERCENTAGE_TOO_HIGH = "707";
  string public constant LPC_INVALID_LTVMANAGER_ADDRESS = "708";
  string public constant LPC_INCONSISTENT_PARAMS = "709";
  string public constant LPC_INVALID_SAFE_HEALTH_FACTOR = "710";
  //reserve config errors
  string public constant RC_INVALID_LTV = "730";
  string public constant RC_INVALID_LIQ_THRESHOLD = "731";
  string public constant RC_INVALID_LIQ_BONUS = "732";
  string public constant RC_INVALID_DECIMALS = "733";
  string public constant RC_INVALID_RESERVE_FACTOR = "734";
  string public constant RC_INVALID_REDEEM_DURATION = "735";
  string public constant RC_INVALID_AUCTION_DURATION = "736";
  string public constant RC_INVALID_REDEEM_FINE = "737";
  string public constant RC_INVALID_REDEEM_THRESHOLD = "738";
  string public constant RC_INVALID_MIN_BID_FINE = "739";
  string public constant RC_INVALID_MAX_BID_FINE = "740";
  string public constant RC_INVALID_MAX_CONFIG_TIMESTAMP = "741";

  //address provider erros
  string public constant LPAPR_PROVIDER_NOT_REGISTERED = "760"; // 'Provider is not registered'
  string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = "761";

  //NFTOracleErrors
  string public constant NFTO_INVALID_PRICEM_ADDRESS = "900";

  //Debt Market
  string public constant DM_CALLER_NOT_THE_OWNER = "1000";
  string public constant DM_DEBT_SHOULD_EXIST = "1001";
  string public constant DM_INVALID_AMOUNT = "1002";
  string public constant DM_FAIL_ON_SEND_ETH = "1003";
  string public constant DM_DEBT_SHOULD_NOT_BE_SOLD = "1004";
  string public constant DM_DEBT_ALREADY_EXIST = "1005";
  string public constant DM_LOAN_SHOULD_EXIST = "1006";
  string public constant DM_AUCTION_ALREADY_ENDED = "1007";
  string public constant DM_BID_PRICE_HIGHER_THAN_SELL_PRICE = "1008";
  string public constant DM_BID_PRICE_LESS_THAN_PREVIOUS_BID = "1009";
  string public constant DM_INVALID_SELL_TYPE = "1010";
  string public constant DM_AUCTION_NOT_ALREADY_ENDED = "1011";
  string public constant DM_INVALID_CLAIM_RECEIVER = "1012";
  string public constant DM_AMOUNT_DIFFERENT_FROM_SELL_PRICE = "1013";
  string public constant DM_BID_PRICE_LESS_THAN_MIN_BID_PRICE = "1014";
  string public constant DM_BORROWED_AMOUNT_DIVERGED = "1015";
  string public constant DM_INVALID_AUTHORIZED_ADDRESS = "1016";
  string public constant DM_CALLER_NOT_THE_OWNER_OR_AUTHORIZED = "1017";
  string public constant DM_INVALID_DELTA_BID_PERCENT = "1018";
  string public constant DM_IS_PAUSED = "1019";
}