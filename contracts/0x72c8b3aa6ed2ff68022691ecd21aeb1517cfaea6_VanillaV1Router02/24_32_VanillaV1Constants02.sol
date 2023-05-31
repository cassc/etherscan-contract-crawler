// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

abstract contract VanillaV1Constants02 {
    error UnauthorizedReentrantAccess();
    error UnauthorizedDelegateCall();
    error UnauthorizedCallback();
    error AllowanceExceeded(uint256 allowed, uint256 actual);
    error SlippageExceeded(uint256 expected, uint256 actual);
    error InvalidSwap(uint256 expected, int256 amountReceived);
    error InvalidUniswapState();
    error UninitializedUniswapPool(address token, uint24 fee);
    error NoTokenPositionFound(address owner, address token);
    error TooManyTradesPerBlock();
    error WrongTradingParameters();
    error UnauthorizedValueSent();
    error InvalidWethAccount();
    error TradeExpired();
    error TokenBalanceExceeded(uint256 tokens, uint112 balance);
    error UnapprovedMigrationTarget(address invalidVersion);

    // constant units for Q-number calculations (https://en.wikipedia.org/wiki/Q_(number_format))
    uint256 internal constant Q32 = 2**32;
    uint256 internal constant Q64 = 2**64;
    uint256 internal constant Q128 = 2**128;
    uint256 internal constant Q192 = 2**192;

    uint32 internal constant MAX_TWAP_PERIOD = 5 minutes;

}