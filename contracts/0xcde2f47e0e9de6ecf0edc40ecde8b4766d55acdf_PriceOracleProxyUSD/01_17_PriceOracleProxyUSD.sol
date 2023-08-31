pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./Denominations.sol";
import "./PriceOracle.sol";
import "./interfaces/FeedRegistryInterface.sol";
import "./interfaces/V1PriceOracleInterface.sol";
import "../CErc20.sol";
import "../CToken.sol";
import "../Exponential.sol";
import "../EIP20Interface.sol";

contract PriceOracleProxyUSD is PriceOracle, Exponential, Denominations {
    /// @notice Admin address
    address public admin;

    /// @notice Guardian address
    address public guardian;

    struct AggregatorInfo {
        /// @notice The base
        address base;
        /// @notice The quote denomination
        address quote;
        /// @notice It's being used or not.
        bool isUsed;
    }

    /// @notice Chainlink Aggregators
    mapping(address => AggregatorInfo) public aggregators;

    /// @notice The v1 price oracle, maintain by CREAM
    V1PriceOracleInterface public v1PriceOracle;

    /// @notice The ChainLink registry address
    FeedRegistryInterface public reg;

    /**
     * @param admin_ The address of admin to set aggregators
     * @param registry_ The address of ChainLink registry
     */
    constructor(
        address admin_,
        address v1PriceOracle_,
        address registry_
    ) public {
        admin = admin_;
        v1PriceOracle = V1PriceOracleInterface(v1PriceOracle_);
        reg = FeedRegistryInterface(registry_);
    }

    /**
     * @notice Get the underlying price of a listed cToken asset
     * @param cToken The cToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18)
     */
    function getUnderlyingPrice(CToken cToken) public view returns (uint256) {
        address underlying = CErc20(address(cToken)).underlying();

        // Get price from ChainLink.
        AggregatorInfo storage aggregatorInfo = aggregators[underlying];
        if (aggregatorInfo.isUsed) {
            uint256 price = getPriceFromChainlink(aggregatorInfo.base, aggregatorInfo.quote);
            if (aggregatorInfo.quote == Denominations.ETH) {
                // Convert the price to USD based if it's ETH based.
                uint256 ethUsdPrice = getPriceFromChainlink(Denominations.ETH, Denominations.USD);
                price = mul_(price, Exp({mantissa: ethUsdPrice}));
            } else if (aggregatorInfo.quote == Denominations.BTC) {
                // Convert the price to USD based if it's BTC based.
                uint256 btcUsdPrice = getPriceFromChainlink(Denominations.BTC, Denominations.USD);
                price = mul_(price, Exp({mantissa: btcUsdPrice}));
            }
            return getNormalizedPrice(price, underlying);
        }

        // Get price from v1.
        uint256 v1Price = getPriceFromV1(underlying);
        if (v1Price > 0) {
            return v1Price;
        }
        revert("price not found");
    }

    /*** Internal fucntions ***/

    /**
     * @notice Get price from ChainLink
     * @param base The base token that ChainLink aggregator gets the price of
     * @param quote The quote token, currenlty support ETH and USD
     * @return The price, scaled by 1e18
     */
    function getPriceFromChainlink(address base, address quote) internal view returns (uint256) {
        (, int256 price, , , ) = reg.latestRoundData(base, quote);
        require(price > 0, "invalid price");

        // Extend the decimals to 1e18.
        return mul_(uint256(price), 10**(18 - uint256(reg.decimals(base, quote))));
    }

    /**
     * @notice Normalize the price according to the token decimals.
     * @param price The original price
     * @param tokenAddress The token address
     * @return The normalized price.
     */
    function getNormalizedPrice(uint256 price, address tokenAddress) internal view returns (uint256) {
        uint256 underlyingDecimals = EIP20Interface(tokenAddress).decimals();
        return mul_(price, 10**(18 - underlyingDecimals));
    }

     /**
     * @notice Get price from v1 price oracle
     * @param token The token to get the price of
     * @return The price
     */
    function getPriceFromV1(address token) internal view returns (uint256) {
        return v1PriceOracle.assetPrices(token);
    }

    /*** Admin or guardian functions ***/

    event AggregatorUpdated(address tokenAddress, address base, address quote, bool isUsed);
    event SetGuardian(address guardian);
    event SetAdmin(address admin);

    /**
     * @notice Set guardian for price oracle proxy
     * @param _guardian The new guardian
     */
    function _setGuardian(address _guardian) external {
        require(msg.sender == admin, "only the admin may set new guardian");
        guardian = _guardian;
        emit SetGuardian(guardian);
    }

    /**
     * @notice Set admin for price oracle proxy
     * @param _admin The new admin
     */
    function _setAdmin(address _admin) external {
        require(msg.sender == admin, "only the admin may set new admin");
        admin = _admin;
        emit SetAdmin(admin);
    }

    /**
     * @notice Set ChainLink aggregators for multiple tokens
     * @param tokenAddresses The list of underlying tokens
     * @param bases The list of ChainLink aggregator bases
     * @param quotes The list of ChainLink aggregator quotes, currently support 'ETH' and 'USD'
     */
    function _setAggregators(
        address[] calldata tokenAddresses,
        address[] calldata bases,
        address[] calldata quotes
    ) external {
        require(msg.sender == admin || msg.sender == guardian, "only the admin or guardian may set the aggregators");
        require(tokenAddresses.length == bases.length && tokenAddresses.length == quotes.length, "mismatched data");
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            bool isUsed;
            if (bases[i] != address(0)) {
                require(msg.sender == admin, "guardian may only clear the aggregator");
                require(quotes[i] == Denominations.ETH || quotes[i] == Denominations.USD || quotes[i] == Denominations.BTC, "unsupported denomination");
                isUsed = true;

                // Make sure the aggregator exists.
                address aggregator = reg.getFeed(bases[i], quotes[i]);
                require(reg.isFeedEnabled(aggregator), "aggregator not enabled");
            }
            aggregators[tokenAddresses[i]] = AggregatorInfo({base: bases[i], quote: quotes[i], isUsed: isUsed});
            emit AggregatorUpdated(tokenAddresses[i], bases[i], quotes[i], isUsed);
        }
    }
}