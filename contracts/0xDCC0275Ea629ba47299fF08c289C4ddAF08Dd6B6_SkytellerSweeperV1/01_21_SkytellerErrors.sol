// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @dev Price feed was address(0x0)
error Skyteller_NullPriceFeed(address token);

/// @dev Price feed returned a negative price,
///      isn't valid in our token use case
error Skyteller_NegativePrice(address token, address feed);

/// @dev Failed to get a price for the token
error Skyteller_PriceFail(address token);

/// @dev Unable to derive a price for the token pair
error Skyteller_NoPriceDerivation(address tokenIn, address tokenOut);

/// @dev Invalid percent value provided
error Skyteller_InvalidPercent();

/// @dev Invalid fee value provided
error Skyteller_InvalidFee();

/// @dev Unable to find a route for the token pair
error Skyteller_NoSwapRoute(address tokenIn, address tokenOut);

/// @dev Open sweep is disabled
error Skyteller_RouterOpenSweepDisabled();

/// @dev Init call to proxy failed
error Skyteller_ProxyFactoryCallFailed();