// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IBasePriceOracle.sol";
import "../external/chainlink/IFeedRegistry.sol";
import "../external/chainlink/Denominations.sol";

/**
 * @title ChainlinkOracleAdapter
 * @author LombardFi
 * @notice Adapted from the official implementation.
 */
contract ChainlinkOracleAdapter is IBasePriceOracle, Ownable {
    /**
     * @notice The feed registry
     * @dev Chainlink feed registry contract.
     * See https://docs.chain.link/docs/data-feeds/feed-registry/
     */
    IFeedRegistry public immutable feedRegistry;

    /**
     * @notice The maximum time allowed after the price update has happened.
     * If the price was updated in more seconds than the maximum time, `getPrice` function
     * returns zero.
     */
    uint256 private constant MAX_ACCEPTABLE_STALENESS = 24 hours;

    /**
     * @notice The address of the wrapped native asset.
     */
    address private immutable weth;

    /**
     * @notice The address of the wrapped native asset.
     */
    address private immutable wbtc;

    /**
     * @notice Assets which are temporarily stopped.
     */
    mapping(address => bool) public disabledAssets;

    /**
     * @notice Constructor that sets the Chainlink feed registry and wrapped native contract.
     * @param _feedRegistry The Chainlink Feed Registry implementation.
     * @param _weth The address of the wrapped native asset e.g. WETH.
     * @param _wbtc The address of the wrapped native asset e.g. WBTC.
     */
    constructor(
        address _feedRegistry,
        address _weth,
        address _wbtc
    ) {
        require(
            _feedRegistry != address(0) &&
                _weth != address(0) &&
                _wbtc != address(0),
            "ChainlinkOracle::zero address"
        );

        feedRegistry = IFeedRegistry(_feedRegistry);
        weth = _weth;
        wbtc = _wbtc;
    }

    /**
     * @notice Function that disables and enables particular assets.
     * @param baseAsset The asset which will be disabled/enabled.
     * @param isEnabled False if the asset should be disabled.
     */
    function setAssetStatus(address baseAsset, bool isEnabled)
        external
        onlyOwner
    {
        require(baseAsset != address(0), "ChainlinkOracle::zero address");

        IAggregatorV3 aggregatorV3 = feedRegistry.getFeed(
            baseAsset,
            Denominations.ETH
        );

        require(
            baseAsset != weth &&
                baseAsset != Denominations.ETH &&
                address(aggregatorV3) != address(0),
            "ChainlinkOracle::not supported"
        );

        disabledAssets[baseAsset] = isEnabled;

        emit AssetStatusSet(baseAsset, isEnabled);
    }

    /**
     * @notice Checks if a token is supported.
     * @dev Only the native token is supported as a quote.
     * @param _baseAsset The asset for whose price is needed.
     * @param _quoteAsset The price denomination
     * @return Whether the oracle supports this asset.
     */
    function supportsAsset(address _baseAsset, address _quoteAsset)
        external
        view
        returns (bool)
    {
        // Supports only native as a denomination, which aren't out of service
        if (
            (_quoteAsset != weth && _quoteAsset != Denominations.ETH) ||
            disabledAssets[_quoteAsset]
        ) {
            return false;
        }

        // Check if `_baseAsset` is equal to the WBTC address
        if (_baseAsset == wbtc) {
            _baseAsset = Denominations.BTC;
        }

        try feedRegistry.getFeed(_baseAsset, Denominations.ETH) returns (
            IAggregatorV3 aggregatorV3
        ) {
            return address(aggregatorV3) != address(0);
        } catch Error(string memory) {
            return false;
        }
    }

    /**
     * @notice Returns the price of an asset denominated in the base asset.
     * @dev Does not throw an error on failure but returns success = false.
     * @return whether the call succeeded and the returned price.
     */
    function getPrice(address _baseAsset, address _quoteAsset)
        external
        view
        returns (bool, uint256)
    {
        // Supports only native as a denomination
        if (
            (_quoteAsset != weth && _quoteAsset != Denominations.ETH) ||
            disabledAssets[_quoteAsset]
        ) {
            return (false, 0);
        }

        // Check if `_baseAsset` is equal to the WBTC address
        if (_baseAsset == wbtc) {
            _baseAsset = Denominations.BTC;
        }

        try
            feedRegistry.latestRoundData(_baseAsset, Denominations.ETH)
        returns (
            uint80,
            int256 tokenEthPrice,
            uint256,
            uint256 updatedAt,
            uint80
        ) {
            if (block.timestamp - updatedAt > MAX_ACCEPTABLE_STALENESS) {
                return (false, 0);
            }

            if (tokenEthPrice <= 0) {
                return (true, 0);
            }

            uint8 decimals = feedRegistry.decimals(
                _baseAsset,
                Denominations.ETH
            );
            uint256 price = (uint256(tokenEthPrice) * 1e18) / 10**decimals;
            return (true, price);
        } catch Error(string memory) {
            return (false, 0);
        }
    }
}