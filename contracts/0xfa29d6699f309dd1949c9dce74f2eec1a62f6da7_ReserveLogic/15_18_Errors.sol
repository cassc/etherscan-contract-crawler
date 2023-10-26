// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

/**
 * @title Errors library
 * @author Kyoko
 * @notice Defines the error messages emitted by the different contracts of the Kyoko protocol
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - MATH = Math libraries
 *  - CT = Common errors between tokens (KToken, VariableDebtToken and StableDebtToken)
 *  - KT = KToken
 *  - SDT = StableDebtToken
 *  - VDT = VariableDebtToken
 *  - KP = KyokoPool
 *  - KF = KyokoFactory
 *  - KPC = KyokoPoolConfiguration
 *  - RL = ReserveLogic
 *  - KPCM = KyokoPoolCollateralManager
 *  - P = Pausable
 */
library Errors {
  //common errors
  string public constant CALLER_NOT_POOL_ADMIN = '25'; // 'The caller must be the pool admin'
  string public constant BORROW_ALLOWANCE_NOT_ENOUGH = '26'; // User borrows on behalf, but allowance are too small
  string public constant ERROR = '27'; // User borrows on behalf, but allowance are too small

  //contract specific errors
  string public constant VL_INVALID_AMOUNT = '1'; // 'Amount must be greater than 0'
  string public constant VL_NO_ACTIVE_RESERVE = '2'; // 'Action requires an active reserve'
  string public constant VL_RESERVE_FROZEN = '3'; // 'Action cannot be performed because the reserve is frozen'
  string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = '4'; // 'User cannot withdraw more than the available balance'
  string public constant VL_INVALID_INTEREST_RATE_MODE_SELECTED = '5'; // 'Invalid interest rate mode selected'
  string public constant VL_BORROWING_NOT_ENABLED = '6'; // 'Borrowing is not enabled'
  string public constant VL_STABLE_BORROWING_NOT_ENABLED = '7'; // stable borrowing not enabled
  string public constant VL_NO_DEBT_OF_SELECTED_TYPE = '8'; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
  string public constant VL_NOT_NFT_OWNER = '9'; // 'User is not the owner of the nft'
  string public constant VL_NOT_SUPPORT = '10'; // 'User's nft for borrow is not support'
  string public constant VL_TOO_EARLY = '11'; // 'Action is earlier than requested'
  string public constant VL_TOO_LATE = '12'; // 'Action is later than requested'
  string public constant VL_BAD_STATUS = '13'; // 'Action with wrong borrow status'
  string public constant VL_INVALID_USER = '14'; // 'User is not borrow owner'
  string public constant VL_AUCTION_ALREADY_SETTLED = '15'; // 'Auction is already done'
  string public constant VL_BAD_PRICE_TO_REPAY = '16'; // 'The floor price below liquidation price'
  string public constant LP_NOT_ENOUGH_STABLE_BORROW_BALANCE = '31'; // 'User does not have any stable rate loan for this reserve'
  string public constant LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '32'; // 'Interest rate rebalance conditions were not met'
  string public constant LP_LIQUIDATION_CALL_FAILED = '33'; // 'Liquidation call failed'
  string public constant LP_REQUESTED_AMOUNT_TOO_SMALL = '34'; // 'The requested amount is too small for an action.'
  string public constant LP_CALLER_NOT_KYOKO_POOL_CONFIGURATOR = '35'; // 'The caller of the function is Kyoko pool configurator'
  string public constant LP_CALLER_NOT_KYOKO_POOL_ORACLE = '36'; // 'The caller of the function is not the Kyoko pool oracle'
  string public constant LP_CALLER_NOT_KYOKO_POOL_FACTORY = '37'; // 'The caller of the function is not the Kyoko pool factory'
  string public constant LP_NFT_ALREADY_EXIST = '38'; // 'The initial reserve nft is already exist'
  string public constant LP_WETH_TRANSFER_FAILED = '39'; // 'Failed to transfer eth and weth'
  string public constant LP_BORROW_FAILED = '41'; // 'Can't be borrowed'
  string public constant LP_LIQUIDITY_INSUFFICIENT = '42'; // 'Insufficient pool balance'
  string public constant LP_IS_PAUSED = '43'; // 'Pool is paused'
  string public constant LP_NO_MORE_RESERVES_ALLOWED = '44';
  string public constant LP_NOT_CONTRACT = '45';
  string public constant LP_NFT_NOT_SUPPORT = '46';
  string public constant CT_CALLER_MUST_BE_KYOKO_POOL = '51'; // 'The caller of this function must be a Kyoko pool'
  string public constant RL_RESERVE_ALREADY_INITIALIZED = '52'; // 'Reserve has already been initialized'
  string public constant KPC_RESERVE_LIQUIDITY_NOT_0 = '53'; // 'The liquidity of the reserve needs to be 0'
  string public constant KPC_CALLER_NOT_EMERGENCY_ADMIN = '54'; // 'The caller must be the emergency admin'
  string public constant KPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '55'; // 'Health factor is not below the threshold'
  string public constant KPCM_LIQUIDATION_DISABLED = '56'; // 'Health factor is not below the threshold'
  string public constant KPCM_NO_ERRORS = '57'; // 'No errors'
  string public constant MATH_MULTIPLICATION_OVERFLOW = '58';
  string public constant MATH_ADDITION_OVERFLOW = '59';
  string public constant MATH_DIVISION_BY_ZERO = '60';
  string public constant RL_LIQUIDITY_INDEX_OVERFLOW = '61'; //  Liquidity index overflows uint128
  string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = '62'; //  Variable borrow index overflows uint128
  string public constant RL_LIQUIDITY_RATE_OVERFLOW = '63'; //  Liquidity rate overflows uint128
  string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = '64'; //  Variable borrow rate overflows uint128
  string public constant RL_STABLE_BORROW_RATE_OVERFLOW = '65'; //  Stable borrow rate overflows uint128
  string public constant CT_INVALID_MINT_AMOUNT = '66'; //invalid amount to mint
  string public constant CT_INVALID_BURN_AMOUNT = '67'; //invalid amount to burn
  string public constant RC_INVALID_RESERVE_FACTOR = '71';
  string public constant RC_INVALID_BORROW_RATIO = '72';
  string public constant RC_INVALID_PERIOD = '73';
  string public constant RC_INVALID_MIN_BORROW_TIME = '74';
  string public constant RC_INVALID_LIQ_THRESHOLD = '75';
  string public constant RC_INVALID_LIQ_TIME = '76';
  string public constant RC_INVALID_BID_TIME = '77';
  string public constant SDT_STABLE_DEBT_OVERFLOW = '81';
  string public constant SDT_BURN_EXCEEDS_BALANCE = '82';
  string public constant SDT_CREATION_FAILED = '83';
  string public constant VDT_CREATION_FAILED = '84';
  string public constant KF_LIQUIDITY_INSUFFICIENT = '85';
  string public constant KT_CREATION_FAILED = '86';
  string public constant KT_ERROR_CREATOR = '87';
  string public constant KT_INITIAL_LIQUIDITY_LOCK = '88';
}