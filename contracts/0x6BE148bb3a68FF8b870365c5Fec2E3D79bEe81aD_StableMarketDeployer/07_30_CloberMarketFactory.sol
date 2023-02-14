// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface CloberMarketFactory {
    /**
     * @notice Emitted when a new volatile market is created.
     * @param market The address of the new market.
     * @param orderToken The address of the new market's order token.
     * @param quoteToken The address of the new market's quote token.
     * @param baseToken The address of the new market's base token.
     * @param quoteUnit The amount that one raw amount represents in quote tokens.
     * @param nonce The nonce for this market.
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The scale factor of the price points.
     * @param r The common ratio between price points.
     */
    event CreateVolatileMarket(
        address indexed market,
        address orderToken,
        address quoteToken,
        address baseToken,
        uint256 quoteUnit,
        uint256 nonce,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 r
    );

    /**
     * @notice Emitted when a new stable market is created.
     * @param market The address of the new market.
     * @param orderToken The address of the new market's order token.
     * @param quoteToken The address of the new market's quote token.
     * @param baseToken The address of the new market's base token.
     * @param quoteUnit The amount that one raw amount represents in quote tokens.
     * @param nonce The nonce for this market.
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The starting price point.
     * @param d The common difference between price points.
     */
    event CreateStableMarket(
        address indexed market,
        address orderToken,
        address quoteToken,
        address baseToken,
        uint256 quoteUnit,
        uint256 nonce,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 d
    );

    /**
     * @notice Emitted when the address of the owner has changed.
     * @param previousOwner The address of the previous owner.
     * @param newOwner The address of the new owner.
     */
    event ChangeOwner(address previousOwner, address newOwner);

    /**
     * @notice Emitted when the DAO Treasury address has changed.
     * @param previousTreasury The address of the previous DAO Treasury.
     * @param newTreasury The address of the new DAO Treasury.
     */
    event ChangeDaoTreasury(address previousTreasury, address newTreasury);

    /**
     * @notice Emitted when the host address has changed.
     * @param market The address of the market that had a change of hosts.
     * @param previousHost The address of the previous host.
     * @param newHost The address of a new host.
     */
    event ChangeHost(address indexed market, address previousHost, address newHost);

    /**
     * @notice Returns the address of the VolatileMarketDeployer.
     * @return The address of the VolatileMarketDeployer.
     */
    function volatileMarketDeployer() external view returns (address);

    /**
     * @notice Returns the address of the StableMarketDeployer.
     * @return The address of the StableMarketDeployer.
     */
    function stableMarketDeployer() external view returns (address);

    /**
     * @notice Returns the address of the OrderCanceler.
     * @return The address of the OrderCanceler.
     */
    function canceler() external view returns (address);

    /**
     * @notice Returns whether the specified token address has been registered as a quote token.
     * @param token The address of the token to check.
     * @return bool Whether the token is registered as a quote token.
     */
    function registeredQuoteTokens(address token) external view returns (bool);

    /**
     * @notice Returns the address of the factory owner
     * @return The address of the factory owner
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the address of the factory owner candidate
     * @return The address of the factory owner candidate
     */
    function futureOwner() external view returns (address);

    /**
     * @notice Returns the address of the DAO Treasury
     * @return The address of the DAO Treasury
     */
    function daoTreasury() external view returns (address);

    /**
     * @notice Returns the current nonce
     * @return The current nonce
     */
    function nonce() external view returns (uint256);

    /**
     * @notice Creates a new market with a VolatilePriceBook.
     * @param host The address of the new market's host.
     * @param quoteToken The address of the new market's quote token.
     * @param baseToken The address of the new market's base token.
     * @param quoteUnit The amount that one raw amount represents in quote tokens.
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The scale factor of the price points.
     * @param r The common ratio between price points.
     * @return The address of the created market.
     */
    function createVolatileMarket(
        address host,
        address quoteToken,
        address baseToken,
        uint96 quoteUnit,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 r
    ) external returns (address);

    /**
     * @notice Creates a new market with a StablePriceBook
     * @param host The address of the new market's host
     * @param quoteToken The address of the new market's quote token
     * @param baseToken The address of the new market's base token
     * @param quoteUnit The amount that one raw amount represents in quote tokens
     * @param makerFee The maker fee.
     * Paid to the maker when negative, paid by the maker when positive.
     * Every 10000 represents a 1% fee on trade volume.
     * @param takerFee The taker fee.
     * Paid by the taker.
     * Every 10000 represents a 1% fee on trade volume.
     * @param a The starting price point.
     * @param d The common difference between price points.
     * @return The address of the created market.
     */
    function createStableMarket(
        address host,
        address quoteToken,
        address baseToken,
        uint96 quoteUnit,
        int24 makerFee,
        uint24 takerFee,
        uint128 a,
        uint128 d
    ) external returns (address);

    /**
     * @notice Change the DAO Treasury address.
     * @dev Only the factory owner can call this function.
     * @param treasury The new address of the DAO Treasury.
     */
    function changeDaoTreasury(address treasury) external;

    /**
     * @notice Sets the new owner address for this contract.
     * @dev Only the factory owner can call this function.
     * @param newOwner The new owner address for this contract.
     */
    function prepareChangeOwner(address newOwner) external;

    /**
     * @notice Changes the owner of this contract to the address set by `prepareChangeOwner`.
     * @dev Only the future owner can call this function.
     */
    function executeChangeOwner() external;

    /**
     * @notice Returns the host address of the given market.
     * @param market The address of the target market.
     * @return The host address of the market.
     */
    function getMarketHost(address market) external view returns (address);

    /**
     * @notice Prepares to set a new host address for the given market address.
     * @dev Only the market host can call this function.
     * @param market The market address for which the host will be changed.
     * @param newHost The new host address for the given market.
     */
    function prepareHandOverHost(address market, address newHost) external;

    /**
     * @notice Changes the host address of the given market to the address set by `prepareHandOverHost`.
     * @dev Only the future market host can call this function.
     * @param market The market address for which the host will be changed.
     */
    function executeHandOverHost(address market) external;

    /**
     * @notice Computes the OrderNFT contract address.
     * @param marketNonce The nonce to compute the OrderNFT contract address via CREATE2.
     */
    function computeTokenAddress(uint256 marketNonce) external view returns (address);

    enum MarketType {
        NONE,
        VOLATILE,
        STABLE
    }

    /**
     * @notice MarketInfo struct that contains information about a market.
     * @param host The address of the market host.
     * @param marketType The market type, either VOLATILE or STABLE.
     * @param a The starting price point.
     * @param factor The either the common ratio or common difference between price points.
     * @param futureHost The address set by `prepareHandOverHost` to change the market host.
     */
    struct MarketInfo {
        address host;
        MarketType marketType;
        uint128 a;
        uint128 factor;
        address futureHost;
    }

    /**
     * @notice Returns key information about the market.
     * @param market The address of the market.
     * @return marketInfo The MarketInfo structure of the given market.
     */
    function getMarketInfo(address market) external view returns (MarketInfo memory marketInfo);

    /**
     * @notice Allows the specified token to be used as the quote token.
     * @dev Only the factory owner can call this function.
     * @param token The address of the token to register.
     */
    function registerQuoteToken(address token) external;

    /**
     * @notice Revokes the token's right to be used as a quote token.
     * @dev Only the factory owner can call this function.
     * @param token The address of the token to unregister.
     */
    function unregisterQuoteToken(address token) external;

    /**
     * @notice Returns the order token name.
     * @param quoteToken The address of the market's quote token.
     * @param baseToken The address of the market's base token.
     * @param marketNonce The market nonce.
     * @return The order token name.
     */
    function formatOrderTokenName(
        address quoteToken,
        address baseToken,
        uint256 marketNonce
    ) external view returns (string memory);

    /**
     * @notice Returns the order token symbol.
     * @param quoteToken The address of a new market's quote token.
     * @param baseToken The address of a new market's base token.
     * @param marketNonce The market nonce.
     * @return The order token symbol.
     */
    function formatOrderTokenSymbol(
        address quoteToken,
        address baseToken,
        uint256 marketNonce
    ) external view returns (string memory);
}