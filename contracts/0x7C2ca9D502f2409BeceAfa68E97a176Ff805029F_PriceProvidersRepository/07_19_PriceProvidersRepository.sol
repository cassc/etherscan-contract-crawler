// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IPriceProvidersRepository.sol";
import "./interfaces/ISiloRepository.sol";
import "./utils/Manageable.sol";
import "./utils/TwoStepOwnable.sol";

import "./lib/TokenHelper.sol";
import "./lib/Ping.sol";

/// @title PriceProvidersRepository
/// @notice A repository of price providers. It manages price providers as well as maps assets to their price
/// provider. It acts as a entry point for Silo for token prices.
/// @custom:security-contact [email protected]
contract PriceProvidersRepository is IPriceProvidersRepository, Manageable, TwoStepOwnable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev we require quote token to have 18 decimals
    uint256 public constant QUOTE_TOKEN_DECIMALS = 18;

    /// @dev Constant used for prices' decimal points, 1e18 is treated as 1
    uint256 private constant _ONE = 1e18;

    /// @notice SiloRepository contract address
    address public immutable siloRepository;
    /// @notice Token in which prices are quoted. It's most likely WETH, however it could vary from deployment
    /// to deployment. For example 1 SILO costs X amount of quoteToken.
    address public immutable override quoteToken;

    /// @notice Maps asset address to its price provider
    /// @dev Each asset must have a price provider contract assigned, otherwise it's not supported
    mapping(address => IPriceProvider) public override priceProviders;

    /// @notice Array of all price providers
    EnumerableSet.AddressSet private _allProviders;

    error AssetNotSupported();
    error InvalidPriceProvider();
    error InvalidPriceProviderQuoteToken();
    error InvalidRepository();
    error OnlyRepository();
    error PriceProviderAlreadyExists();
    error PriceProviderDoesNotExist();
    error PriceProviderNotRegistered();
    error QuoteTokenNotSupported();

    modifier onlyRepository() {
        if (msg.sender != siloRepository) revert OnlyRepository();
        _;
    }

    /// @param _quoteToken address of quote token
    /// @param _siloRepository address of SiloRepository
    constructor(address _quoteToken, address _siloRepository) Manageable(msg.sender) {
        if (TokenHelper.assertAndGetDecimals(_quoteToken) != QUOTE_TOKEN_DECIMALS) {
          revert QuoteTokenNotSupported();
        }

        if (!Ping.pong(ISiloRepository(_siloRepository).siloRepositoryPing)) {
            revert InvalidRepository();
        }

        siloRepository = _siloRepository;
        quoteToken = _quoteToken;
    }

    /// @inheritdoc IPriceProvidersRepository
    function addPriceProvider(IPriceProvider _provider) external override onlyOwner {
        if (!Ping.pong(_provider.priceProviderPing)) revert InvalidPriceProvider();

        if (_provider.quoteToken() != quoteToken) revert InvalidPriceProviderQuoteToken();

        if (!_allProviders.add(address(_provider))) revert PriceProviderAlreadyExists();

        emit NewPriceProvider(_provider);
    }

    /// @inheritdoc IPriceProvidersRepository
    function removePriceProvider(IPriceProvider _provider) external virtual override onlyOwner {
        if (!_allProviders.remove(address(_provider))) revert PriceProviderDoesNotExist();

        emit PriceProviderRemoved(_provider);
    }

    /// @inheritdoc IPriceProvidersRepository
    function setPriceProviderForAsset(address _asset, IPriceProvider _provider) external virtual override onlyManager {
        if (!_allProviders.contains(address(_provider))) {
            revert PriceProviderNotRegistered();
        }

        if (!_provider.assetSupported(_asset)) revert AssetNotSupported();

        emit PriceProviderForAsset(_asset, _provider);
        priceProviders[_asset] = _provider;
    }

    /// @inheritdoc IPriceProvidersRepository
    function isPriceProvider(IPriceProvider _provider) external view override returns (bool) {
        return _allProviders.contains(address(_provider));
    }

    /// @inheritdoc IPriceProvidersRepository
    function providersCount() external view override returns (uint256) {
        return _allProviders.length();
    }

    /// @inheritdoc IPriceProvidersRepository
    function providerList() external view override returns (address[] memory) {
        return _allProviders.values();
    }

    /// @inheritdoc IPriceProvidersRepository
    function providersReadyForAsset(address _asset) external view override returns (bool) {
        // quote token is supported by default because getPrice() returns _ONE as its price by default
        if (_asset == quoteToken) return true;

        IPriceProvider priceProvider = priceProviders[_asset];
        if (address(priceProvider) == address(0)) return false;

        return priceProvider.assetSupported(_asset);
    }

    /// @inheritdoc IPriceProvidersRepository
    function priceProvidersRepositoryPing() external pure override returns (bytes4) {
        return this.priceProvidersRepositoryPing.selector;
    }

    /// @inheritdoc IPriceProvidersRepository
    function manager() public view override(Manageable, IPriceProvidersRepository) returns (address) {
        return Manageable.manager();
    }

    /// @inheritdoc TwoStepOwnable
    function owner() public view override(Manageable, TwoStepOwnable) returns (address) {
        return TwoStepOwnable.owner();
    }

    /// @inheritdoc IPriceProvidersRepository
    function getPrice(address _asset) public view override virtual returns (uint256) {
        if (_asset == quoteToken) return _ONE;

        if (address(priceProviders[_asset]) == address(0)) revert AssetNotSupported();

        return priceProviders[_asset].getPrice(_asset);
    }
}