// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title ExchangeRate
 * 
 * @dev Encapsulates the rate of exchange from asset a to asset b. 
 * EXAMPLE: 
 * a=25, b=24 -> you get 24 b for every 25 a exchanged. 
 * a=100, b=101 -> you get 1 extra b for every 100 a's; a 1% difference. 
 * 
 * @author John R. Kosinski
 * Owned and Managed by Stream Finance
 */
struct ExchangeRate {
    uint256 vaultToken;
    uint256 baseToken;
}