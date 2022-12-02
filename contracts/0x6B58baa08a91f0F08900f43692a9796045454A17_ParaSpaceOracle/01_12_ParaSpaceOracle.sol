// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IEACAggregatorProxy} from "../interfaces/IEACAggregatorProxy.sol";

import {Errors} from "../protocol/libraries/helpers/Errors.sol";
import {IACLManager} from "../interfaces/IACLManager.sol";
import {IAtomicPriceAggregator} from "../interfaces/IAtomicPriceAggregator.sol";
import {IPoolAddressesProvider} from "../interfaces/IPoolAddressesProvider.sol";
import {IPriceOracleGetter} from "../interfaces/IPriceOracleGetter.sol";
import {IParaSpaceOracle} from "../interfaces/IParaSpaceOracle.sol";

/**
 * @title ParaSpaceOracle
 *
 * @notice Contract to get asset prices, manage price sources and update the fallback oracle
 * - Use of Chainlink Aggregators as first source of price
 * - If the returned price by a Chainlink aggregator is <= 0, the call is forwarded to a fallback oracle
 * - Owned by the ParaSpace governance
 */
contract ParaSpaceOracle is IParaSpaceOracle {
    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    // Map of asset price sources (asset => priceSource)
    mapping(address => address) private assetsSources;

    IPriceOracleGetter private _fallbackOracle;
    address public immutable override BASE_CURRENCY;
    uint256 public immutable override BASE_CURRENCY_UNIT;

    /**
     * @dev Only asset listing or pool admin can call functions marked by this modifier.
     **/
    modifier onlyAssetListingOrPoolAdmins() {
        _onlyAssetListingOrPoolAdmins();
        _;
    }

    /**
     * @notice Constructor
     * @param provider The address of the new PoolAddressesProvider
     * @param assets The addresses of the assets
     * @param sources The address of the source of each asset
     * @param fallbackOracle The address of the fallback oracle to use if the data of an
     *        aggregator is not consistent
     * @param baseCurrency The base currency used for the price quotes. If USD is used, base currency is 0x0
     * @param baseCurrencyUnit The unit of the base currency
     */
    constructor(
        IPoolAddressesProvider provider,
        address[] memory assets,
        address[] memory sources,
        address fallbackOracle,
        address baseCurrency,
        uint256 baseCurrencyUnit
    ) {
        ADDRESSES_PROVIDER = provider;
        BASE_CURRENCY = baseCurrency;
        BASE_CURRENCY_UNIT = baseCurrencyUnit;
        _setFallbackOracle(fallbackOracle);
        _setAssetsSources(assets, sources);
        emit BaseCurrencySet(baseCurrency, baseCurrencyUnit);
    }

    /// @inheritdoc IParaSpaceOracle
    function setAssetSources(
        address[] calldata assets,
        address[] calldata sources
    ) external override onlyAssetListingOrPoolAdmins {
        _setAssetsSources(assets, sources);
    }

    /// @inheritdoc IParaSpaceOracle
    function setFallbackOracle(address fallbackOracle)
        external
        override
        onlyAssetListingOrPoolAdmins
    {
        _setFallbackOracle(fallbackOracle);
    }

    /**
     * @notice Internal function to set the sources for each asset
     * @param assets The addresses of the assets
     * @param sources The address of the source of each asset
     */
    function _setAssetsSources(
        address[] memory assets,
        address[] memory sources
    ) internal {
        require(
            assets.length == sources.length,
            Errors.INCONSISTENT_PARAMS_LENGTH
        );
        for (uint256 i = 0; i < assets.length; i++) {
            require(
                assets[i] != BASE_CURRENCY,
                Errors.SET_ORACLE_SOURCE_NOT_ALLOWED
            );
            assetsSources[assets[i]] = sources[i];
            emit AssetSourceUpdated(assets[i], sources[i]);
        }
    }

    /**
     * @notice Internal function to set the fallback oracle
     * @param fallbackOracle The address of the fallback oracle
     */
    function _setFallbackOracle(address fallbackOracle) internal {
        _fallbackOracle = IPriceOracleGetter(fallbackOracle);
        emit FallbackOracleUpdated(fallbackOracle);
    }

    /// @inheritdoc IPriceOracleGetter
    function getAssetPrice(address asset)
        public
        view
        override
        returns (uint256)
    {
        if (asset == BASE_CURRENCY) {
            return BASE_CURRENCY_UNIT;
        }

        uint256 price = 0;
        IEACAggregatorProxy source = IEACAggregatorProxy(assetsSources[asset]);
        if (address(source) != address(0)) {
            price = uint256(source.latestAnswer());
        }
        if (price == 0 && address(_fallbackOracle) != address(0)) {
            price = _fallbackOracle.getAssetPrice(asset);
        }

        require(price != 0, Errors.ORACLE_PRICE_NOT_READY);
        return price;
    }

    function getTokenPrice(address asset, uint256 tokenId)
        external
        view
        override
        returns (uint256)
    {
        IAtomicPriceAggregator source = IAtomicPriceAggregator(
            assetsSources[asset]
        );

        if (address(source) != address(0)) {
            return source.getTokenPrice(tokenId);
        }

        revert(Errors.ORACLE_PRICE_NOT_READY);
    }

    function getTokensPrices(address asset, uint256[] calldata tokenIds)
        external
        view
        override
        returns (uint256[] memory)
    {
        IAtomicPriceAggregator source = IAtomicPriceAggregator(
            assetsSources[asset]
        );

        if (address(source) != address(0)) {
            return source.getTokensPrices(tokenIds);
        }

        revert(Errors.ORACLE_PRICE_NOT_READY);
    }

    function getTokensPricesSum(address asset, uint256[] calldata tokenIds)
        external
        view
        override
        returns (uint256)
    {
        IAtomicPriceAggregator source = IAtomicPriceAggregator(
            assetsSources[asset]
        );

        if (address(source) != address(0)) {
            return source.getTokensPricesSum(tokenIds);
        }

        revert(Errors.ORACLE_PRICE_NOT_READY);
    }

    /// @inheritdoc IParaSpaceOracle
    function getAssetsPrices(address[] calldata assets)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory prices = new uint256[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            prices[i] = getAssetPrice(assets[i]);
        }
        return prices;
    }

    /// @inheritdoc IParaSpaceOracle
    function getSourceOfAsset(address asset)
        external
        view
        override
        returns (address)
    {
        return assetsSources[asset];
    }

    /// @inheritdoc IParaSpaceOracle
    function getFallbackOracle() external view returns (address) {
        return address(_fallbackOracle);
    }

    function _onlyAssetListingOrPoolAdmins() internal view {
        IACLManager aclManager = IACLManager(
            ADDRESSES_PROVIDER.getACLManager()
        );
        require(
            aclManager.isAssetListingAdmin(msg.sender) ||
                aclManager.isPoolAdmin(msg.sender),
            Errors.CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN
        );
    }
}