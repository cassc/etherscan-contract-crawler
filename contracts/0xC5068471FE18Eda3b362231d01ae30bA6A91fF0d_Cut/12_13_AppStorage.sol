// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IUniswapV2Pair } from '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

library AppStorage {
	// =============================================================================
	// Token
	// =============================================================================
	struct TokenStore {
        address uniswapV2Pair;

		bool isSwapping;

        address marketingWallet;

        uint256 maxTransactionAmount;
        uint256 swapTokensAtAmount;
        uint256 maxWalletAmount;

        bool isLimitsInEffect;
        bool isTradingActive;
        bool isSwapEnabled;
        bool isLaunched;

        uint256 buyFee;
        uint256 sellFee;

        uint256 feeAmount;

        // exlcude from fees and max transaction amount
        mapping(address => bool) isExcludedFromFee;
        mapping(address => bool) isExcludedFromMaxTransactionAmount;

        // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
        // could be subject to a maximum transfer amount
        mapping(address => bool) isAMMPairs;
	}
	bytes32 internal constant TOKEN_STORE_SLOT = keccak256('cut/storage/token');
	function getTokenStore() internal pure returns (TokenStore storage s) {
		bytes32 position = TOKEN_STORE_SLOT;
		assembly {
			s.slot := position
		}
	}
}