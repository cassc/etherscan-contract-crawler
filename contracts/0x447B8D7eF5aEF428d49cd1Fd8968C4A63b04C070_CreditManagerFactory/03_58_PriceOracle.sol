// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { IPriceFeedType } from "../interfaces/IPriceFeedType.sol";
import { PriceFeedChecker } from "./PriceFeedChecker.sol";
import { IPriceOracleV2 } from "../interfaces/IPriceOracle.sol";
import { ACLTrait } from "../core/ACLTrait.sol";

// CONSTANTS

// EXCEPTIONS
import { ZeroAddressException, AddressIsNotContractException, IncorrectPriceFeedException, IncorrectTokenContractException } from "../interfaces/IErrors.sol";

struct PriceFeedConfig {
    address token;
    address priceFeed;
}

uint256 constant SKIP_PRICE_CHECK_FLAG = 1 << 161;
uint256 constant DECIMALS_SHIFT = 162;

/// @title Price Oracle based on Chainlink's price feeds
/// @notice Works as router and provide cross rates using converting via USD
contract PriceOracle is ACLTrait, IPriceOracleV2, PriceFeedChecker {
    using Address for address;

    /// @dev Map of token addresses to corresponding price feeds and their parameters,
    ///      encoded into a single uint256
    mapping(address => uint256) internal _priceFeeds;

    // Contract version
    uint256 public constant version = 2;

    constructor(address addressProvider, PriceFeedConfig[] memory defaults)
        ACLTrait(addressProvider)
    {
        uint256 len = defaults.length;
        for (uint256 i = 0; i < len; ) {
            _addPriceFeed(defaults[i].token, defaults[i].priceFeed); // F:[PO-1]

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Sets a price feed if it doesn't exist, or updates an existing one
    /// @param token Address of the token to set the price feed for
    /// @param priceFeed Address of a USD price feed adhering to Chainlink's interface
    function addPriceFeed(address token, address priceFeed)
        external
        configuratorOnly
    {
        _addPriceFeed(token, priceFeed);
    }

    /// @dev IMPLEMENTATION: addPriceFeed
    /// @param token Address of the token to set the price feed for
    /// @param priceFeed Address of a USD price feed adhering to Chainlink's interface
    function _addPriceFeed(address token, address priceFeed) internal {
        if (token == address(0) || priceFeed == address(0))
            revert ZeroAddressException(); // F:[PO-2]

        if (!token.isContract()) revert AddressIsNotContractException(token); // F:[PO-2]

        if (!priceFeed.isContract())
            revert AddressIsNotContractException(priceFeed); // F:[PO-2]

        try AggregatorV3Interface(priceFeed).decimals() returns (
            uint8 _decimals
        ) {
            if (_decimals != 8) revert IncorrectPriceFeedException(); // F:[PO-2]
        } catch {
            revert IncorrectPriceFeedException(); // F:[PO-2]
        }

        bool skipCheck;

        try IPriceFeedType(priceFeed).skipPriceCheck() returns (bool property) {
            skipCheck = property; // F:[PO-2]
        } catch {}

        uint8 decimals;
        try ERC20(token).decimals() returns (uint8 _decimals) {
            if (_decimals > 18) revert IncorrectTokenContractException(); // F:[PO-2]

            decimals = _decimals; // F:[PO-3]
        } catch {
            revert IncorrectTokenContractException(); // F:[PO-2]
        }

        try AggregatorV3Interface(priceFeed).latestRoundData() returns (
            uint80 roundID,
            int256 price,
            uint256,
            uint256 updatedAt,
            uint80 answeredInRound
        ) {
            // Checks result if skipCheck is not set
            if (!skipCheck)
                _checkAnswer(roundID, price, updatedAt, answeredInRound);
        } catch {
            revert IncorrectPriceFeedException(); // F:[PO-2]
        }

        _setPriceFeedWithFlags(token, priceFeed, skipCheck, decimals);

        emit NewPriceFeed(token, priceFeed); // F:[PO-3]
    }

    /// @dev Returns token's price in USD (8 decimals)
    /// @param token The token to compute the price for
    function getPrice(address token)
        public
        view
        override
        returns (uint256 price)
    {
        (price, ) = _getPrice(token);
    }

    /// @dev IMPLEMENTATION: getPrice
    function _getPrice(address token)
        internal
        view
        returns (uint256 price, uint256 decimals)
    {
        address priceFeed;
        bool skipCheck;
        (priceFeed, skipCheck, decimals) = priceFeedsWithFlags(token); //

        (
            uint80 roundID,
            int256 _price,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = AggregatorV3Interface(priceFeed).latestRoundData(); // F:[PO-6]

        // Checks if SKIP_PRICE_CHECK_FLAG is not set
        if (!skipCheck)
            _checkAnswer(roundID, _price, updatedAt, answeredInRound); // F:[PO-5]

        price = (uint256(_price)); // F:[PO-6]
    }

    /// @dev Converts a quantity of an asset to USD (decimals = 8).
    /// @param amount Amount to convert
    /// @param token Address of the token to be converted
    function convertToUSD(uint256 amount, address token)
        public
        view
        override
        returns (uint256)
    {
        (uint256 price, uint256 decimals) = _getPrice(token);
        return (amount * price) / (10**decimals); // F:[PO-7]
    }

    /// @dev Converts a quantity of USD (decimals = 8) to an equivalent amount of an asset
    /// @param amount Amount to convert
    /// @param token Address of the token converted to
    function convertFromUSD(uint256 amount, address token)
        public
        view
        override
        returns (uint256)
    {
        (uint256 price, uint256 decimals) = _getPrice(token);
        return (amount * (10**decimals)) / price; // F:[PO-7]
    }

    /// @dev Converts one asset into another
    ///
    /// @param amount Amount to convert
    /// @param tokenFrom Address of the token to convert from
    /// @param tokenTo Address of the token to convert to
    function convert(
        uint256 amount,
        address tokenFrom,
        address tokenTo
    ) public view override returns (uint256) {
        return convertFromUSD(convertToUSD(amount, tokenFrom), tokenTo); // F:[PO-8]
    }

    /// @dev Returns collateral values for two tokens, required for a fast check
    /// @param amountFrom Amount of the outbound token
    /// @param tokenFrom Address of the outbound token
    /// @param amountTo Amount of the inbound token
    /// @param tokenTo Address of the inbound token
    /// @return collateralFrom Value of the outbound token amount in USD
    /// @return collateralTo Value of the inbound token amount in USD
    function fastCheck(
        uint256 amountFrom,
        address tokenFrom,
        uint256 amountTo,
        address tokenTo
    )
        external
        view
        override
        returns (uint256 collateralFrom, uint256 collateralTo)
    {
        collateralFrom = convertToUSD(amountFrom, tokenFrom); // F:[PO-9]
        collateralTo = convertToUSD(amountTo, tokenTo); // F:[PO-9]
    }

    /// @dev Returns the price feed address for the passed token
    /// @param token Token to get the price feed for
    function priceFeeds(address token)
        external
        view
        override
        returns (address priceFeed)
    {
        (priceFeed, , ) = priceFeedsWithFlags(token); // F:[PO-3]
    }

    /// @dev Returns the price feed for the passed token,
    ///      with additional parameters
    /// @param token Token to get the price feed for
    function priceFeedsWithFlags(address token)
        public
        view
        override
        returns (
            address priceFeed,
            bool skipCheck,
            uint256 decimals
        )
    {
        uint256 pf = _priceFeeds[token]; // F:[PO-3]
        if (pf == 0) revert PriceOracleNotExistsException();

        priceFeed = address(uint160(pf)); // F:[PO-3]

        skipCheck = pf & SKIP_PRICE_CHECK_FLAG != 0; // F:[PO-3]
        decimals = pf >> DECIMALS_SHIFT;
    }

    /// @dev Encodes the price feed address with parameters into a uint256,
    ///      and saves it into a map
    /// @param token Address of the token to add the price feed for
    /// @param priceFeed Address of the price feed
    /// @param skipCheck Whether price feed result sanity checks should be skipped
    /// @param decimals Decimals for the price feed's result
    function _setPriceFeedWithFlags(
        address token,
        address priceFeed,
        bool skipCheck,
        uint8 decimals
    ) internal {
        uint256 value = uint160(priceFeed); // F:[PO-3]
        if (skipCheck) value |= SKIP_PRICE_CHECK_FLAG; // F:[PO-3]

        _priceFeeds[token] = value + (uint256(decimals) << DECIMALS_SHIFT); // F:[PO-3]
    }
}