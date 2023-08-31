// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

/**
 * @title Errors library
 * @author HopeLend
 * @notice Defines the error messages emitted by the different contracts of the HopeLend protocol
 */
library Errors {
  string public constant CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN = '5'; // 'The caller of the function is not an asset listing or pool admin'
  string public constant INCONSISTENT_PARAMS_LENGTH = '76'; // 'Array parameters that should be equal length are not'
  string public constant ZERO_ADDRESS_NOT_VALID = '77'; // 'Zero address not valid'
  string public constant FAILOVER_ALREADY_ACTIVE = '92'; // Failover is already active
  string public constant FAILOVER_ALREADY_DEACTIVATED = '93'; // Failover is already deactivated
}