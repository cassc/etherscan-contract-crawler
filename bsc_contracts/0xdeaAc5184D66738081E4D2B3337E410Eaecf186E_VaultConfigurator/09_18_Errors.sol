// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

/**
 * @title Errors library
 * @author Aave
 * @author Onebit
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - MATH = Math libraries
 *  - CT = Common errors between tokens (OToken)
 *  - AT = OToken
 *  - V = Vault
 *  - VAPR = VaultAddressesProviderRegistry
 *  - VC = VaultConfiguration
 *  - RL = ReserveLogic
 *  - P = Pausable
 */
library Errors {
  //common errors
  string public constant CALLER_NOT_VAULT_ADMIN = '33'; // 'The caller must be the vault admin'
  string public constant BORROW_ALLOWANCE_NOT_ENOUGH = '59'; // User borrows on behalf, but allowance are too small

  //contract specific errors
  string public constant VL_INVALID_AMOUNT = '1'; // 'Amount must be greater than 0'
  string public constant VL_NO_ACTIVE_RESERVE = '2'; // 'Action requires an active reserve'
  string public constant VL_RESERVE_FROZEN = '3'; // 'Action cannot be performed because the reserve is frozen'
  string public constant VL_CURRENT_AVAILABLE_LIQUIDITY_NOT_ENOUGH = '4'; // 'The current liquidity is not enough'
  string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = '5'; // 'User cannot withdraw more than the available balance'
  string public constant VL_TRANSFER_NOT_ALLOWED = '6'; // 'Transfer cannot be allowed.'
  string public constant VL_NOT_IN_PURCHASE_OR_REDEMPTION_PERIOD = '7'; // 'Not in purchase or redemption period.'
  string public constant VL_PURCHASE_UPPER_LIMIT = '8'; // 'Purchase upper limit.'
  string public constant VL_NOT_IN_LOCK_PERIOD = '9'; // 'Not in lock period.'
  string public constant VL_NOT_FINISHED = '10'; // 'Lastest period is not finished yet.'
  string public constant VL_INVALID_TIMESTAMP = '11'; // 'Timestamps must be in order.'
  string public constant VL_INVALID_FUND_ADDRESS = '12'; // 'Invalid fund address.'
  string public constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = '19'; // 'The underlying balance needs to be greater than 0'
  string public constant V_INCONSISTENT_PROTOCOL_ACTUAL_BALANCE = '26'; // 'The actual balance of the protocol is inconsistent'
  string public constant V_CALLER_NOT_VAULT_CONFIGURATOR = '27';
  string public constant V_CALLER_NOT_VAULT_OPERATOR = '28'; // 'The caller of the function is not the vault operator.'
  string public constant CT_CALLER_MUST_BE_VAULT = '29'; // 'The caller of this function must be a vault'
  string public constant CT_CANNOT_GIVE_ALLOWANCE_TO_HIMSELF = '30'; // 'User cannot give allowance to himself'
  string public constant CT_TRANSFER_AMOUNT_NOT_GT_0 = '31'; // 'Transferred amount needs to be greater than zero'
  string public constant RL_RESERVE_ALREADY_INITIALIZED = '32'; // 'Reserve has already been initialized'
  string public constant VPC_RESERVE_LIQUIDITY_NOT_0 = '34'; // 'The liquidity of the reserve needs to be 0'
  string public constant VPC_INVALID_OTOKEN_VAULT_ADDRESS = '35'; // 'The liquidity of the reserve needs to be 0'
  string public constant VPC_INVALID_ADDRESSES_PROVIDER_ID = '40'; // 'The liquidity of the reserve needs to be 0'
  string public constant VPC_INVALID_CONFIGURATION = '75'; // 'Invalid risk parameters for the reserve'
  string public constant VPC_CALLER_NOT_EMERGENCY_ADMIN = '76'; // 'The caller must be the emergency admin'
  string public constant VAPR_PROVIDER_NOT_REGISTERED = '41'; // 'Provider is not registered'
  string public constant VCM_NO_ERRORS = '46'; // 'No errors'
  string public constant MATH_MULTIPLICATION_OVERFLOW = '48';
  string public constant MATH_ADDITION_OVERFLOW = '49';
  string public constant MATH_DIVISION_BY_ZERO = '50';
  string public constant RL_LIQUIDITY_INDEX_OVERFLOW = '51'; //  Liquidity index overflows uint128
  string public constant RL_LIQUIDITY_RATE_OVERFLOW = '53'; //  Liquidity rate overflows uint128
  string public constant CT_INVALID_MINT_AMOUNT = '56'; //invalid amount to mint
  string public constant CT_INVALID_BURN_AMOUNT = '58'; //invalid amount to burn
  string public constant V_REENTRANCY_NOT_ALLOWED = '62';
  string public constant V_CALLER_MUST_BE_AN_OTOKEN = '63';
  string public constant V_IS_PAUSED = '64'; // 'Vault is paused'
  string public constant V_NO_MORE_RESERVES_ALLOWED = '65';
  string public constant V_NOT_IN_WHITELIST = '66';
  string public constant RC_INVALID_DECIMALS = '70';
  string public constant VAPR_INVALID_ADDRESSES_PROVIDER_ID = '72';
  string public constant UL_INVALID_INDEX = '77';
  string public constant V_NOT_CONTRACT = '78';
  string public constant SDT_BURN_EXCEEDS_BALANCE = '80';
  string public constant CT_CALLER_MUST_BE_CLAIM_ADMIN = '81';
  string public constant CT_TOKEN_CAN_NOT_BE_UNDERLYING = '82';
  string public constant CT_TOKEN_CAN_NOT_BE_SELF = '83';
  string public constant VPC_CALLER_NOT_KYC_ADMIN = '84';
  string public constant VPC_CALLER_NOT_PORTFOLIO_MANAGER = '85';

}