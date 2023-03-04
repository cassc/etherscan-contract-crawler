// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {Constants} from "joe-v2/libraries/Constants.sol";
import {IJoeFactory} from "joe-v2/interfaces/IJoeFactory.sol";
import {IJoePair} from "joe-v2/interfaces/IJoePair.sol";
import {ILBFactory} from "joe-v2/interfaces/ILBFactory.sol";
import {ILBLegacyFactory} from "joe-v2/interfaces/ILBLegacyFactory.sol";
import {ILBLegacyPair} from "joe-v2/interfaces/ILBLegacyPair.sol";
import {ILBLegacyRouter} from "joe-v2/interfaces/ILBLegacyRouter.sol";
import {ILBPair} from "joe-v2/interfaces/ILBPair.sol";
import {ILBRouter} from "joe-v2/interfaces/ILBRouter.sol";
import {Uint256x256Math} from "joe-v2/libraries/math/Uint256x256Math.sol";
import {IERC20Metadata, IERC20} from "openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import {
    ISafeAccessControlEnumerable, SafeAccessControlEnumerable
} from "solrary/access/SafeAccessControlEnumerable.sol";

import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";
import {IJoeDexLens} from "./interfaces/IJoeDexLens.sol";

/**
 * @title Joe Dex Lens
 * @author Trader Joe
 * @notice This contract allows to price tokens in either Native or a usd stable token.
 * It could be easily extended to any collateral. Owner can grant or revoke role to add data feeds to price a token
 * and can set the weight of the different data feeds. When no data feed is provided for both collateral, the contract
 * will use cascade through TOKEN/WNative and TOKEN/USD pools on v2.1, v2 and v1 to find a price.
 */
contract JoeDexLens is SafeAccessControlEnumerable, IJoeDexLens {
    using Uint256x256Math for uint256;

    bytes32 public constant DATA_FEED_MANAGER_ROLE = keccak256("DATA_FEED_MANAGER_ROLE");

    uint256 private constant _DECIMALS = 18;
    uint256 private constant _PRECISION = 10 ** _DECIMALS;

    IJoeFactory private immutable _FACTORY_V1;
    ILBLegacyFactory private immutable _LEGACY_FACTORY_V2;
    ILBFactory private immutable _FACTORY_V2_1;
    ILBLegacyRouter private immutable _LEGACY_ROUTER_V2;
    ILBRouter private immutable _ROUTER_V2_1;

    address private immutable _WNATIVE;
    address private immutable _USD_STABLE_COIN;

    uint256 private constant _BIN_WIDTH = 5;

    /**
     * @dev Mapping from a collateral token to a token to an enumerable set of data feeds used to get the price of the token in collateral
     * e.g. STABLECOIN => Native will return datafeeds to get the price of Native in USD
     * And Native => JOE will return datafeeds to get the price of JOE in Native
     */
    mapping(address => mapping(address => DataFeedSet)) private _whitelistedDataFeeds;

    /**
     * Modifiers *
     */

    /**
     * @notice Verify that the two lengths match
     * @dev Revert if length are not equal
     * @param lengthA The length of the first list
     * @param lengthB The length of the second list
     */
    modifier verifyLengths(uint256 lengthA, uint256 lengthB) {
        if (lengthA != lengthB) revert JoeDexLens__LengthsMismatch();
        _;
    }

    /**
     * @notice Verify a data feed
     * @dev Revert if :
     * - The collateral and the token are the same address
     * - The collateral is not one of the two tokens of the pair (if the dfType is V1 or V2)
     * - The token is not one of the two tokens of the pair (if the dfType is V1 or V2)
     * @param collateral The address of the collateral (STABLECOIN or WNATIVE)
     * @param token The address of the token
     * @param dataFeed The data feeds information
     */
    modifier verifyDataFeed(address collateral, address token, DataFeed calldata dataFeed) {
        if (collateral == token) revert JoeDexLens__SameTokens();

        if (dataFeed.dfType == dfType.V1) {
            if (address(_FACTORY_V1) == address(0)) revert JoeDexLens__V1ContractNotSet();
        } else if (dataFeed.dfType == dfType.V2) {
            if (address(_LEGACY_FACTORY_V2) == address(0) || address(_LEGACY_ROUTER_V2) == address(0)) {
                revert JoeDexLens__V2ContractNotSet();
            }
        } else if (dataFeed.dfType == dfType.V2_1) {
            if (address(_FACTORY_V2_1) == address(0) || address(_ROUTER_V2_1) == address(0)) {
                revert JoeDexLens__V2_1ContractNotSet();
            }
        } else if (dataFeed.dfType != dfType.CHAINLINK) {
            (address tokenA, address tokenB) = _getTokens(dataFeed);

            if (tokenA != collateral && tokenB != collateral) {
                revert JoeDexLens__CollateralNotInPair(dataFeed.dfAddress, collateral);
            }
            if (tokenA != token && tokenB != token) revert JoeDexLens__TokenNotInPair(dataFeed.dfAddress, token);
        }
        _;
    }

    /**
     * @notice Verify the weight for a data feed
     * @dev Revert if the weight is equal to 0
     * @param weight The weight of a data feed
     */
    modifier verifyWeight(uint88 weight) {
        if (weight == 0) revert JoeDexLens__NullWeight();
        _;
    }

    /**
     * Constructor *
     */

    constructor(
        ILBRouter lbRouter,
        ILBFactory lbFactory,
        ILBLegacyRouter lbLegacyRouter,
        ILBLegacyFactory lbLegacyFactory,
        IJoeFactory joeFactory,
        address wnative,
        address usdStableCoin
    ) {
        // revert if all addresses are zero
        if (
            address(lbRouter) == address(0) && address(lbFactory) == address(0) && address(lbLegacyRouter) == address(0)
                && address(lbLegacyFactory) == address(0) && address(joeFactory) == address(0)
        ) {
            revert JoeDexLens__ZeroAddress();
        }

        if (address(lbRouter) != address(0)) {
            if (lbRouter.getFactory() != lbFactory) revert JoeDexLens__LBV2_1AddressMismatch();
            if (
                address(lbLegacyRouter) != address(0) && address(lbLegacyFactory) != address(0)
                    && (lbRouter.getLegacyRouter() != lbLegacyRouter || lbRouter.getLegacyFactory() != lbLegacyFactory)
            ) {
                revert JoeDexLens__LBV2AddressMismatch();
            }
            if (address(joeFactory) != address(0) && lbRouter.getV1Factory() != joeFactory) {
                revert JoeDexLens__JoeV1AddressMismatch();
            }
            if (address(lbRouter.getWAVAX()) != wnative) revert JoeDexLens__WNativeMismatch();
        } else if (address(lbFactory) != address(0)) {
            // Make sure that if lbRouter is not set, lbFactory is not set either
            revert JoeDexLens__LBV2_1AddressMismatch();
        }

        if (address(lbLegacyRouter) != address(0)) {
            // Sanity check that the getIdFromPrice function exists
            try lbLegacyRouter.getIdFromPrice(ILBLegacyPair(address(0)), 0) {} catch {}
            lbLegacyFactory.getNumberOfLBPairs(); // Sanity check
        } else if (address(lbLegacyFactory) != address(0)) {
            // Make sure that if lbLegacyRouter is not set, lbLegacyFactory is not set either
            revert JoeDexLens__LBV2AddressMismatch();
        }

        if (address(joeFactory) != address(0)) joeFactory.allPairsLength(); // Sanity check

        if (wnative == address(0) || usdStableCoin == address(0)) revert JoeDexLens__ZeroAddress();

        _ROUTER_V2_1 = lbRouter;
        _FACTORY_V2_1 = lbFactory;

        _LEGACY_ROUTER_V2 = lbLegacyRouter;
        _LEGACY_FACTORY_V2 = lbLegacyFactory;

        _FACTORY_V1 = joeFactory;

        _WNATIVE = wnative;
        _USD_STABLE_COIN = usdStableCoin;
    }

    /**
     * External View Functions *
     */

    /**
     * @notice Returns the address of the wrapped native token
     * @return wNative The address of the wrapped native token
     */
    function getWNative() external view override returns (address wNative) {
        return _WNATIVE;
    }

    /**
     * @notice Returns the address of the usd stable coin
     * @return stableCoin The address of the usd stable coin
     */
    function getUSDStableCoin() external view override returns (address stableCoin) {
        return _USD_STABLE_COIN;
    }

    /**
     * @notice Returns the address of the router v2
     * @return legacyRouterV2 The address of the router v2
     */
    function getLegacyRouterV2() external view override returns (ILBLegacyRouter legacyRouterV2) {
        return _LEGACY_ROUTER_V2;
    }

    /**
     * @notice Returns the address of the router v2.1
     * @return routerV2 The address of the router v2.1
     */
    function getRouterV2() external view override returns (ILBRouter routerV2) {
        return _ROUTER_V2_1;
    }

    /**
     * @notice Returns the address of the factory v1
     * @return factoryV1 The address of the factory v1
     */
    function getFactoryV1() external view override returns (IJoeFactory factoryV1) {
        return _FACTORY_V1;
    }

    /**
     * @notice Returns the address of the factory v2
     * @return legacyFactoryV2 The address of the factory v2
     */
    function getLegacyFactoryV2() external view override returns (ILBLegacyFactory legacyFactoryV2) {
        return _LEGACY_FACTORY_V2;
    }

    /**
     * @notice Returns the address of the factory v2.1
     * @return factoryV2 The address of the factory v2.1
     */
    function getFactoryV2() external view override returns (ILBFactory factoryV2) {
        return _FACTORY_V2_1;
    }

    /**
     * @notice Returns the list of data feeds used to calculate the price of the token in stable coin
     * @param token The address of the token
     * @return dataFeeds The array of data feeds used to price `token` in stable coin
     */
    function getUSDDataFeeds(address token) external view override returns (DataFeed[] memory dataFeeds) {
        return _whitelistedDataFeeds[_USD_STABLE_COIN][token].dataFeeds;
    }

    /**
     * @notice Returns the list of data feeds used to calculate the price of the token in Native
     * @param token The address of the token
     * @return dataFeeds The array of data feeds used to price `token` in Native
     */
    function getNativeDataFeeds(address token) external view override returns (DataFeed[] memory dataFeeds) {
        return _whitelistedDataFeeds[_WNATIVE][token].dataFeeds;
    }

    /**
     * @notice Returns the price of token in USD, scaled with 6 decimals
     * @param token The address of the token
     * @return price The price of the token in USD, with 6 decimals
     */
    function getTokenPriceUSD(address token) external view override returns (uint256 price) {
        return _getTokenWeightedAveragePrice(_USD_STABLE_COIN, token);
    }

    /**
     * @notice Returns the price of token in Native, scaled with `_DECIMALS` decimals
     * @param token The address of the token
     * @return price The price of the token in Native, with `_DECIMALS` decimals
     */
    function getTokenPriceNative(address token) external view override returns (uint256 price) {
        return _getTokenWeightedAveragePrice(_WNATIVE, token);
    }

    /**
     * @notice Returns the prices of each token in USD, scaled with 6 decimals
     * @param tokens The list of address of the tokens
     * @return prices The prices of each token in USD, with 6 decimals
     */
    function getTokensPricesUSD(address[] calldata tokens) external view override returns (uint256[] memory prices) {
        return _getTokenWeightedAveragePrices(_USD_STABLE_COIN, tokens);
    }

    /**
     * @notice Returns the prices of each token in Native, scaled with `_DECIMALS` decimals
     * @param tokens The list of address of the tokens
     * @return prices The prices of each token in Native, with `_DECIMALS` decimals
     */
    function getTokensPricesNative(address[] calldata tokens)
        external
        view
        override
        returns (uint256[] memory prices)
    {
        return _getTokenWeightedAveragePrices(_WNATIVE, tokens);
    }

    /**
     * Owner Functions *
     */

    /**
     * @notice Add a USD data feed for a specific token
     * @dev Can only be called by the owner
     * @param token The address of the token
     * @param dataFeed The USD data feeds information
     */
    function addUSDDataFeed(address token, DataFeed calldata dataFeed)
        external
        override
        onlyOwnerOrRole(DATA_FEED_MANAGER_ROLE)
    {
        _addDataFeed(_USD_STABLE_COIN, token, dataFeed);
    }

    /**
     * @notice Add a Native data feed for a specific token
     * @dev Can only be called by the owner
     * @param token The address of the token
     * @param dataFeed The Native data feeds information
     */
    function addNativeDataFeed(address token, DataFeed calldata dataFeed)
        external
        override
        onlyOwnerOrRole(DATA_FEED_MANAGER_ROLE)
    {
        _addDataFeed(_WNATIVE, token, dataFeed);
    }

    /**
     * @notice Set the USD weight for a specific data feed of a token
     * @dev Can only be called by the owner
     * @param token The address of the token
     * @param dfAddress The USD data feed address
     * @param newWeight The new weight of the data feed
     */
    function setUSDDataFeedWeight(address token, address dfAddress, uint88 newWeight)
        external
        override
        onlyOwnerOrRole(DATA_FEED_MANAGER_ROLE)
    {
        _setDataFeedWeight(_USD_STABLE_COIN, token, dfAddress, newWeight);
    }

    /**
     * @notice Set the Native weight for a specific data feed of a token
     * @dev Can only be called by the owner
     * @param token The address of the token
     * @param dfAddress The data feed address
     * @param newWeight The new weight of the data feed
     */
    function setNativeDataFeedWeight(address token, address dfAddress, uint88 newWeight)
        external
        override
        onlyOwnerOrRole(DATA_FEED_MANAGER_ROLE)
    {
        _setDataFeedWeight(_WNATIVE, token, dfAddress, newWeight);
    }

    /**
     * @notice Remove a USD data feed of a token
     * @dev Can only be called by the owner
     * @param token The address of the token
     * @param dfAddress The USD data feed address
     */
    function removeUSDDataFeed(address token, address dfAddress)
        external
        override
        onlyOwnerOrRole(DATA_FEED_MANAGER_ROLE)
    {
        _removeDataFeed(_USD_STABLE_COIN, token, dfAddress);
    }

    /**
     * @notice Remove a Native data feed of a token
     * @dev Can only be called by the owner
     * @param token The address of the token
     * @param dfAddress The data feed address
     */
    function removeNativeDataFeed(address token, address dfAddress)
        external
        override
        onlyOwnerOrRole(DATA_FEED_MANAGER_ROLE)
    {
        _removeDataFeed(_WNATIVE, token, dfAddress);
    }

    /**
     * @notice Batch add USD data feed for each (token, data feed)
     * @dev Can only be called by the owner
     * @param tokens The addresses of the tokens
     * @param dataFeeds The list of USD data feeds informations
     */
    function addUSDDataFeeds(address[] calldata tokens, DataFeed[] calldata dataFeeds)
        external
        override
        onlyOwnerOrRole(DATA_FEED_MANAGER_ROLE)
    {
        _addDataFeeds(_USD_STABLE_COIN, tokens, dataFeeds);
    }

    /**
     * @notice Batch add Native data feed for each (token, data feed)
     * @dev Can only be called by the owner
     * @param tokens The addresses of the tokens
     * @param dataFeeds The list of Native data feeds informations
     */
    function addNativeDataFeeds(address[] calldata tokens, DataFeed[] calldata dataFeeds)
        external
        override
        onlyOwnerOrRole(DATA_FEED_MANAGER_ROLE)
    {
        _addDataFeeds(_WNATIVE, tokens, dataFeeds);
    }

    /**
     * @notice Batch set the USD weight for each (token, data feed)
     * @dev Can only be called by the owner
     * @param tokens The list of addresses of the tokens
     * @param dfAddresses The list of USD data feed addresses
     * @param newWeights The list of new weights of the data feeds
     */
    function setUSDDataFeedsWeights(
        address[] calldata tokens,
        address[] calldata dfAddresses,
        uint88[] calldata newWeights
    ) external override onlyOwnerOrRole(DATA_FEED_MANAGER_ROLE) {
        _setDataFeedsWeights(_USD_STABLE_COIN, tokens, dfAddresses, newWeights);
    }

    /**
     * @notice Batch set the Native weight for each (token, data feed)
     * @dev Can only be called by the owner
     * @param tokens The list of addresses of the tokens
     * @param dfAddresses The list of Native data feed addresses
     * @param newWeights The list of new weights of the data feeds
     */
    function setNativeDataFeedsWeights(
        address[] calldata tokens,
        address[] calldata dfAddresses,
        uint88[] calldata newWeights
    ) external override onlyOwnerOrRole(DATA_FEED_MANAGER_ROLE) {
        _setDataFeedsWeights(_WNATIVE, tokens, dfAddresses, newWeights);
    }

    /**
     * @notice Batch remove a list of USD data feeds for each (token, data feed)
     * @dev Can only be called by the owner
     * @param tokens The list of addresses of the tokens
     * @param dfAddresses The list of USD data feed addresses
     */
    function removeUSDDataFeeds(address[] calldata tokens, address[] calldata dfAddresses)
        external
        override
        onlyOwnerOrRole(DATA_FEED_MANAGER_ROLE)
    {
        _removeDataFeeds(_USD_STABLE_COIN, tokens, dfAddresses);
    }

    /**
     * @notice Batch remove a list of Native data feeds for each (token, data feed)
     * @dev Can only be called by the owner
     * @param tokens The list of addresses of the tokens
     * @param dfAddresses The list of Native data feed addresses
     */
    function removeNativeDataFeeds(address[] calldata tokens, address[] calldata dfAddresses)
        external
        override
        onlyOwnerOrRole(DATA_FEED_MANAGER_ROLE)
    {
        _removeDataFeeds(_WNATIVE, tokens, dfAddresses);
    }

    /**
     * Private Functions *
     */

    /**
     * @notice Returns the data feed length for a specific collateral and a token
     * @param collateral The address of the collateral (USDC or WNATIVE)
     * @param token The address of the token
     * @return length The number of data feeds
     */
    function _getDataFeedsLength(address collateral, address token) private view returns (uint256 length) {
        return _whitelistedDataFeeds[collateral][token].dataFeeds.length;
    }

    /**
     * @notice Returns the data feed at index `index` for a specific collateral and a token
     * @param collateral The address of the collateral (USDC or WNATIVE)
     * @param token The address of the token
     * @param index The index
     * @return dataFeed the data feed at index `index`
     */
    function _getDataFeedAt(address collateral, address token, uint256 index)
        private
        view
        returns (DataFeed memory dataFeed)
    {
        return _whitelistedDataFeeds[collateral][token].dataFeeds[index];
    }

    /**
     * @notice Returns if a (tokens)'s set contains the data feed address
     * @param collateral The address of the collateral (USDC or WNATIVE)
     * @param token The address of the token
     * @param dfAddress The data feed address
     * @return Whether the set contains the data feed address (true) or not (false)
     */
    function dataFeedContains(address collateral, address token, address dfAddress) private view returns (bool) {
        return _whitelistedDataFeeds[collateral][token].indexes[dfAddress] != 0;
    }

    /**
     * @notice Add a data feed to a set, return true if it was added, false if not
     * @param collateral The address of the collateral (USDC or WNATIVE)
     * @param token The address of the token
     * @param dataFeed The data feeds information
     * @return Whether the data feed was added (true) to the set or not (false)
     */
    function _addToSet(address collateral, address token, DataFeed calldata dataFeed) private returns (bool) {
        if (!dataFeedContains(collateral, token, dataFeed.dfAddress)) {
            DataFeedSet storage set = _whitelistedDataFeeds[collateral][token];

            set.dataFeeds.push(dataFeed);
            set.indexes[dataFeed.dfAddress] = set.dataFeeds.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Remove a data feed from a set, returns true if it was removed, false if not
     * @param collateral The address of the collateral (USDC or WNATIVE)
     * @param token The address of the token
     * @param dfAddress The data feed address
     * @return Whether the data feed was removed (true) from the set or not (false)
     */
    function _removeFromSet(address collateral, address token, address dfAddress) private returns (bool) {
        DataFeedSet storage set = _whitelistedDataFeeds[collateral][token];
        uint256 dataFeedIndex = set.indexes[dfAddress];

        if (dataFeedIndex != 0) {
            uint256 toDeleteIndex = dataFeedIndex - 1;
            uint256 lastIndex = set.dataFeeds.length - 1;

            if (toDeleteIndex != lastIndex) {
                DataFeed memory lastDataFeed = set.dataFeeds[lastIndex];

                set.dataFeeds[toDeleteIndex] = lastDataFeed;
                set.indexes[lastDataFeed.dfAddress] = dataFeedIndex;
            }

            set.dataFeeds.pop();
            delete set.indexes[dfAddress];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Add a data feed to a set, revert if it couldn't add it
     * @param collateral The address of the collateral (USDC or WNATIVE)
     * @param token The address of the token
     * @param dataFeed The data feeds information
     */
    function _addDataFeed(address collateral, address token, DataFeed calldata dataFeed)
        private
        verifyDataFeed(collateral, token, dataFeed)
        verifyWeight(dataFeed.dfWeight)
    {
        if (!_addToSet(collateral, token, dataFeed)) {
            revert JoeDexLens__DataFeedAlreadyAdded(collateral, token, dataFeed.dfAddress);
        }

        emit DataFeedAdded(collateral, token, dataFeed);
    }

    /**
     * @notice Batch add data feed for each (collateral, token, data feed)
     * @param collateral The address of the collateral (USDC or WNATIVE)
     * @param tokens The addresses of the tokens
     * @param dataFeeds The list of USD data feeds informations
     */
    function _addDataFeeds(address collateral, address[] calldata tokens, DataFeed[] calldata dataFeeds)
        private
        verifyLengths(tokens.length, dataFeeds.length)
    {
        for (uint256 i; i < tokens.length;) {
            _addDataFeed(collateral, tokens[i], dataFeeds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Set the weight for a specific data feed of a (collateral, token)
     * @param collateral The address of the collateral (USDC or WNATIVE)
     * @param token The address of the token
     * @param dfAddress The data feed address
     * @param newWeight The new weight of the data feed
     */
    function _setDataFeedWeight(address collateral, address token, address dfAddress, uint88 newWeight)
        private
        verifyWeight(newWeight)
    {
        DataFeedSet storage set = _whitelistedDataFeeds[collateral][token];

        uint256 index = set.indexes[dfAddress];

        if (index == 0) revert JoeDexLens__DataFeedNotInSet(collateral, token, dfAddress);

        set.dataFeeds[index - 1].dfWeight = newWeight;

        emit DataFeedsWeightSet(collateral, token, dfAddress, newWeight);
    }

    /**
     * @notice Batch set the weight for each (collateral, token, data feed)
     * @param collateral The address of the collateral (USDC or WNATIVE)
     * @param tokens The list of addresses of the tokens
     * @param dfAddresses The list of USD data feed addresses
     * @param newWeights The list of new weights of the data feeds
     */
    function _setDataFeedsWeights(
        address collateral,
        address[] calldata tokens,
        address[] calldata dfAddresses,
        uint88[] calldata newWeights
    ) private verifyLengths(tokens.length, dfAddresses.length) verifyLengths(tokens.length, newWeights.length) {
        for (uint256 i; i < tokens.length;) {
            _setDataFeedWeight(collateral, tokens[i], dfAddresses[i], newWeights[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Remove a data feed from a set, revert if it couldn't remove it
     * @param collateral The address of the collateral (USDC or WNATIVE)
     * @param token The address of the token
     * @param dfAddress The data feed address
     */
    function _removeDataFeed(address collateral, address token, address dfAddress) private {
        if (!_removeFromSet(collateral, token, dfAddress)) {
            revert JoeDexLens__DataFeedNotInSet(collateral, token, dfAddress);
        }

        emit DataFeedRemoved(collateral, token, dfAddress);
    }

    /**
     * @notice Batch remove a list of collateral data feeds for each (token, data feed)
     * @param collateral The address of the collateral (USDC or WNATIVE)
     * @param tokens The list of addresses of the tokens
     * @param dfAddresses The list of USD data feed addresses
     */
    function _removeDataFeeds(address collateral, address[] calldata tokens, address[] calldata dfAddresses)
        private
        verifyLengths(tokens.length, dfAddresses.length)
    {
        for (uint256 i; i < tokens.length;) {
            _removeDataFeed(collateral, tokens[i], dfAddresses[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Return the weighted average price of a token using its collateral data feeds
     * @dev If no data feed was provided, will use `_getPriceAnyToken` to try to find a valid price
     * @param collateral The address of the collateral (USDC or WNATIVE)
     * @param token The address of the token
     * @return price The weighted average price of the token, with the collateral's decimals
     */
    function _getTokenWeightedAveragePrice(address collateral, address token) private view returns (uint256 price) {
        uint256 decimals = IERC20Metadata(collateral).decimals();
        if (collateral == token) return 10 ** decimals;

        uint256 length = _getDataFeedsLength(collateral, token);

        if (length == 0) {
            // fallback on other collateral
            address otherCollateral = collateral == _WNATIVE ? _USD_STABLE_COIN : _WNATIVE;

            uint256 lengthOtherCollateral = _getDataFeedsLength(otherCollateral, token);
            uint256 lengthCollateral = _getDataFeedsLength(otherCollateral, collateral);

            if (lengthOtherCollateral == 0 || lengthCollateral == 0) {
                return _getPriceAnyToken(collateral, token);
            }

            uint256 tokenPrice = _getTokenWeightedAveragePrice(otherCollateral, token);
            uint256 collateralPrice = _getTokenWeightedAveragePrice(otherCollateral, collateral);

            // Both price are in the same decimals
            return tokenPrice * 10 ** decimals / collateralPrice;
        }

        uint256 dfPrice;
        uint256 totalWeights;
        for (uint256 i; i < length;) {
            DataFeed memory dataFeed = _getDataFeedAt(collateral, token, i);

            if (dataFeed.dfType == dfType.V1) {
                dfPrice = _getPriceFromV1(dataFeed.dfAddress, token);
            } else if (dataFeed.dfType == dfType.V2) {
                dfPrice = _getPriceFromV2(dataFeed.dfAddress, token);
            } else if (dataFeed.dfType == dfType.V2_1) {
                dfPrice = _getPriceFromV2_1(dataFeed.dfAddress, token);
            } else if (dataFeed.dfType == dfType.CHAINLINK) {
                dfPrice = _getPriceFromChainlink(dataFeed.dfAddress);
            } else {
                revert JoeDexLens__UnknownDataFeedType();
            }

            price += dfPrice * dataFeed.dfWeight;
            totalWeights += dataFeed.dfWeight;

            unchecked {
                ++i;
            }
        }

        price /= totalWeights;

        // Return the price with the collateral's decimals
        if (decimals < _DECIMALS) price /= 10 ** (_DECIMALS - decimals);
        else if (decimals > _DECIMALS) price *= 10 ** (decimals - _DECIMALS);
    }

    /**
     * @notice Batch function to return the weighted average price of each tokens using its collateral data feeds
     * @dev If no data feed was provided, will use `_getPriceAnyToken` to try to find a valid price
     * @param collateral The address of the collateral (USDC or WNATIVE)
     * @param tokens The list of addresses of the tokens
     * @return prices The list of weighted average price of each token, with the collateral's decimals
     */
    function _getTokenWeightedAveragePrices(address collateral, address[] calldata tokens)
        private
        view
        returns (uint256[] memory prices)
    {
        prices = new uint256[](tokens.length);
        for (uint256 i; i < tokens.length;) {
            prices[i] = _getTokenWeightedAveragePrice(collateral, tokens[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Return the price tracked by the aggreagator using chainlink's data feed, with `_DECIMALS` decimals
     * @param dfAddress The address of the data feed
     * @return price The price tracked by the aggreagator, with `_DECIMALS` decimals
     */
    function _getPriceFromChainlink(address dfAddress) private view returns (uint256 price) {
        AggregatorV3Interface aggregator = AggregatorV3Interface(dfAddress);

        (, int256 sPrice,,,) = aggregator.latestRoundData();
        if (sPrice <= 0) revert JoeDexLens__InvalidChainLinkPrice();

        price = uint256(sPrice);

        uint256 aggregatorDecimals = aggregator.decimals();

        // Return the price with `_DECIMALS` decimals
        if (aggregatorDecimals < _DECIMALS) price *= 10 ** (_DECIMALS - aggregatorDecimals);
        else if (aggregatorDecimals > _DECIMALS) price /= 10 ** (aggregatorDecimals - _DECIMALS);
    }

    /**
     * @notice Return the price of the token denominated in the second token of the V1 pair, with `_DECIMALS` decimals
     * @dev The `token` token needs to be on of the two paired token of the given pair
     * @param pairAddress The address of the pair
     * @param token The address of the token
     * @return price The price of the token, with `_DECIMALS` decimals
     */
    function _getPriceFromV1(address pairAddress, address token) private view returns (uint256 price) {
        IJoePair pair = IJoePair(pairAddress);

        address token0 = pair.token0();
        address token1 = pair.token1();

        uint256 decimals0 = IERC20Metadata(token0).decimals();
        uint256 decimals1 = IERC20Metadata(token1).decimals();

        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();

        // Return the price with `_DECIMALS` decimals
        if (token == token0) {
            return (reserve1 * 10 ** (decimals0 + _DECIMALS)) / (reserve0 * 10 ** decimals1);
        } else if (token == token1) {
            return (reserve0 * 10 ** (decimals1 + _DECIMALS)) / (reserve1 * 10 ** decimals0);
        } else {
            revert JoeDexLens__WrongPair();
        }
    }

    /**
     * @notice Return the price of the token denominated in the second token of the V2 pair, with `_DECIMALS` decimals
     * @dev The `token` token needs to be on of the two paired token of the given pair
     * @param pairAddress The address of the pair
     * @param token The address of the token
     * @return price The price of the token, with `_DECIMALS` decimals
     */
    function _getPriceFromV2(address pairAddress, address token) private view returns (uint256 price) {
        ILBLegacyPair pair = ILBLegacyPair(pairAddress);

        (,, uint256 activeID) = pair.getReservesAndId();
        uint256 priceScaled = _LEGACY_ROUTER_V2.getPriceFromId(pair, uint24(activeID));

        address tokenX = address(pair.tokenX());
        address tokenY = address(pair.tokenY());

        uint256 decimalsX = IERC20Metadata(tokenX).decimals();
        uint256 decimalsY = IERC20Metadata(tokenY).decimals();

        // Return the price with `_DECIMALS` decimals
        if (token == tokenX) {
            return priceScaled.mulShiftRoundDown(10 ** (18 + decimalsX - decimalsY), Constants.SCALE_OFFSET);
        } else if (token == tokenY) {
            return (type(uint256).max / priceScaled).mulShiftRoundDown(
                10 ** (18 + decimalsY - decimalsX), Constants.SCALE_OFFSET
            );
        } else {
            revert JoeDexLens__WrongPair();
        }
    }

    /**
     * @notice Return the price of the token denominated in the second token of the V2.1 pair, with `_DECIMALS` decimals
     * @dev The `token` token needs to be on of the two paired token of the given pair
     * @param pairAddress The address of the pair
     * @param token The address of the token
     * @return price The price of the token, with `_DECIMALS` decimals
     */
    function _getPriceFromV2_1(address pairAddress, address token) private view returns (uint256 price) {
        ILBPair pair = ILBPair(pairAddress);

        uint256 activeID = pair.getActiveId();
        uint256 priceScaled = _ROUTER_V2_1.getPriceFromId(pair, uint24(activeID));

        address tokenX = address(pair.getTokenX());
        address tokenY = address(pair.getTokenY());

        uint256 decimalsX = IERC20Metadata(tokenX).decimals();
        uint256 decimalsY = IERC20Metadata(tokenY).decimals();

        // Return the price with `_DECIMALS` decimals
        if (token == tokenX) {
            return priceScaled.mulShiftRoundDown(10 ** (18 + decimalsX - decimalsY), Constants.SCALE_OFFSET);
        } else if (token == tokenY) {
            return (type(uint256).max / priceScaled).mulShiftRoundDown(
                10 ** (18 + decimalsY - decimalsX), Constants.SCALE_OFFSET
            );
        } else {
            revert JoeDexLens__WrongPair();
        }
    }

    /**
     * @notice Return the addresses of the two tokens of a pair
     * @dev Work with both V1 or V2 pairs
     * @param dataFeed The data feeds information
     * @return tokenA The address of the first token of the pair
     * @return tokenB The address of the second token of the pair
     */
    function _getTokens(DataFeed calldata dataFeed) private view returns (address tokenA, address tokenB) {
        if (dataFeed.dfType == dfType.V1) {
            IJoePair pair = IJoePair(dataFeed.dfAddress);

            tokenA = pair.token0();
            tokenB = pair.token1();
        } else if (dataFeed.dfType == dfType.V2) {
            ILBLegacyPair pair = ILBLegacyPair(dataFeed.dfAddress);

            tokenA = address(pair.tokenX());
            tokenB = address(pair.tokenY());
        } else if (dataFeed.dfType == dfType.V2_1) {
            ILBPair pair = ILBPair(dataFeed.dfAddress);

            tokenA = address(pair.getTokenX());
            tokenB = address(pair.getTokenY());
        } else {
            revert JoeDexLens__UnknownDataFeedType();
        }
    }

    /**
     * @notice Tries to find the price of the token on v2.1, v2 and v1 pairs.
     * V2.1 and v2 pairs are checked to have enough liquidity in them,
     * to avoid pricing using stale pools
     * @dev Will revert if no pools were created
     * @param collateral The address of the collateral (USDC or WNATIVE)
     * @param token The address of the token
     * @return price The weighted average, based on pair's liquidity, of the token with the collateral's decimals
     */
    function _getPriceAnyToken(address collateral, address token) private view returns (uint256 price) {
        // First check the token price on v2.1
        price = _v2_1FallbackPrice(collateral, token);

        // Then on v2
        if (price == 0) {
            price = _v2FallbackPrice(collateral, token);
        }

        // If none of the above worked, check with the other collateral
        if (price == 0) {
            address otherCollateral = collateral == _WNATIVE ? _USD_STABLE_COIN : _WNATIVE;

            // First check the token price on v2.1
            uint256 priceTokenOtherCollateral = _v2_1FallbackPrice(otherCollateral, token);

            // Then on v2
            if (priceTokenOtherCollateral == 0) {
                priceTokenOtherCollateral = _v2FallbackPrice(otherCollateral, token);
            }

            // If it worked, convert the price with the correct collateral
            if (priceTokenOtherCollateral > 0) {
                uint256 collateralPrice = _getTokenWeightedAveragePrice(otherCollateral, collateral);

                uint256 collateralDecimals = IERC20Metadata(collateral).decimals();
                uint256 otherCollateralDecimals = IERC20Metadata(otherCollateral).decimals();

                price = priceTokenOtherCollateral * 10 ** (_DECIMALS + collateralDecimals - otherCollateralDecimals)
                    / collateralPrice;
            }
        }

        // If none of the above worked, check on v1 pairs
        if (price == 0) {
            price = _v1FallbackPrice(collateral, token);
        }
    }

    /**
     * @notice Loops through all the collateral/token v2.1 pairs and returns the price of the token if a valid one was found
     * @param collateral The address of the collateral
     * @param token The address of the token
     * @return price The price of the token, with the collateral's decimals (0 if no valid pair was found)
     */
    function _v2_1FallbackPrice(address collateral, address token) private view returns (uint256 price) {
        if (address(_FACTORY_V2_1) == address(0) || address(_ROUTER_V2_1) == address(0)) {
            return 0;
        }

        ILBFactory.LBPairInformation[] memory lbPairsAvailable =
            _FACTORY_V2_1.getAllLBPairs(IERC20(collateral), IERC20(token));

        if (lbPairsAvailable.length != 0) {
            for (uint256 i = 0; i < lbPairsAvailable.length; i++) {
                if (
                    _validateV2_1Pair(
                        lbPairsAvailable[i].LBPair,
                        IERC20Metadata(address(lbPairsAvailable[i].LBPair.getTokenX())).decimals(),
                        IERC20Metadata(address(lbPairsAvailable[i].LBPair.getTokenY())).decimals()
                    )
                ) {
                    return _getPriceFromV2_1(address(lbPairsAvailable[i].LBPair), token);
                }
            }
        }
    }

    /**
     * @notice Loops through all the collateral/token v2 pairs and returns the price of the token if a valid one was found
     * @param collateral The address of the collateral
     * @param token The address of the token
     * @return price The price of the token, with the collateral's decimals (0 if no valid pair was found)
     */
    function _v2FallbackPrice(address collateral, address token) private view returns (uint256 price) {
        if (address(_LEGACY_FACTORY_V2) == address(0) || address(_LEGACY_ROUTER_V2) == address(0)) {
            return 0;
        }

        ILBLegacyFactory.LBPairInformation[] memory lbPairsAvailable =
            _LEGACY_FACTORY_V2.getAllLBPairs(IERC20(collateral), IERC20(token));

        if (lbPairsAvailable.length != 0) {
            for (uint256 i = 0; i < lbPairsAvailable.length; i++) {
                if (
                    _validateV2Pair(
                        lbPairsAvailable[i].LBPair,
                        IERC20Metadata(address(lbPairsAvailable[i].LBPair.tokenX())).decimals(),
                        IERC20Metadata(address(lbPairsAvailable[i].LBPair.tokenY())).decimals()
                    )
                ) {
                    return _getPriceFromV2(address(lbPairsAvailable[i].LBPair), token);
                }
            }
        }
    }

    /**
     * @notice Fetchs the collateral/token and otherCollateral/token v1 pairs and returns the price of the token if a valid one was found
     * @param collateral The address of the collateral
     * @param token The address of the token
     * @return price The price of the token, with the collateral's decimals
     */
    function _v1FallbackPrice(address collateral, address token) private view returns (uint256 price) {
        if (address(_FACTORY_V1) == address(0)) return 0;

        address pairTokenWNative = _FACTORY_V1.getPair(token, _WNATIVE);
        address pairTokenUsdc = _FACTORY_V1.getPair(token, _USD_STABLE_COIN);

        if (pairTokenWNative != address(0) && pairTokenUsdc != address(0)) {
            uint256 priceOfNative = _getTokenWeightedAveragePrice(collateral, _WNATIVE);
            uint256 priceOfUSDC = _getTokenWeightedAveragePrice(collateral, _USD_STABLE_COIN);

            uint256 priceInUSDC = _getPriceFromV1(pairTokenUsdc, token);
            uint256 priceInNative = _getPriceFromV1(pairTokenWNative, token);

            uint256 totalReserveInUSDC = _getReserveInTokenAFromV1(pairTokenUsdc, _USD_STABLE_COIN, token);
            uint256 totalReserveinWNative = _getReserveInTokenAFromV1(pairTokenWNative, _WNATIVE, token);

            uint256 weightUSDC = (totalReserveInUSDC * priceOfUSDC) / _PRECISION;
            uint256 weightWNative = (totalReserveinWNative * priceOfNative) / _PRECISION;

            uint256 totalWeights;
            uint256 weightedPriceUSDC = (priceInUSDC * priceOfUSDC * weightUSDC) / _PRECISION;
            if (weightedPriceUSDC != 0) totalWeights += weightUSDC;

            uint256 weightedPriceNative = (priceInNative * priceOfNative * weightWNative) / _PRECISION;
            if (weightedPriceNative != 0) totalWeights += weightWNative;

            if (totalWeights == 0) revert JoeDexLens__NotEnoughLiquidity();

            return (weightedPriceUSDC + weightedPriceNative) / totalWeights;
        } else if (pairTokenWNative != address(0)) {
            return _getPriceInCollateralFromV1(collateral, pairTokenWNative, _WNATIVE, token);
        } else if (pairTokenUsdc != address(0)) {
            return _getPriceInCollateralFromV1(collateral, pairTokenUsdc, _USD_STABLE_COIN, token);
        } else {
            revert JoeDexLens__PairsNotCreated();
        }
    }

    /**
     * @notice Checks if a v2.1 pair is valid
     * @dev A pair is valid if the total reserves of the pair are above the minimum threshold
     * and the reserves of the _BIN_WIDTH bin around the active bin are above the minimum threshold
     * @param pair The pair to validate
     * @param tokenXDecimals The decimals of the token X
     * @param tokenYDecimals The decimals of the token Y
     * @return isValid True if the pair is valid, false otherwise
     */
    function _validateV2_1Pair(ILBPair pair, uint256 tokenXDecimals, uint256 tokenYDecimals)
        private
        view
        returns (bool isValid)
    {
        uint256 activeId = pair.getActiveId();

        (uint256 reserveX, uint256 reserveY) = pair.getReserves();

        // Skip if the total reserves of the pair are too low
        if (!_validateReserves(reserveX, reserveY, tokenXDecimals, tokenYDecimals)) {
            return false;
        }

        // Skip if the reserves of the _BIN_WIDTH bin around the active bin are too low
        reserveX = reserveY = 0;
        for (uint256 i = activeId - _BIN_WIDTH; i <= activeId + _BIN_WIDTH; i++) {
            (uint256 binReserveX, uint256 binReserveY) = pair.getBin(uint24(i));
            reserveX += binReserveX;
            reserveY += binReserveY;
        }

        if (!_validateReserves(reserveX, reserveY, tokenXDecimals, tokenYDecimals)) {
            return false;
        }

        return true;
    }

    /**
     * @notice Checks if a v2 pair is valid
     * @dev A pair is valid if the total reserves of the pair are above the minimum threshold
     * and the reserves of the _BIN_WIDTH bin around the active bin are above the minimum threshold
     * @param pair The pair to validate
     * @param tokenXDecimals The decimals of the token X
     * @param tokenYDecimals The decimals of the token Y
     * @return isValid True if the pair is valid, false otherwise
     */
    function _validateV2Pair(ILBLegacyPair pair, uint256 tokenXDecimals, uint256 tokenYDecimals)
        private
        view
        returns (bool isValid)
    {
        (uint256 reserveX, uint256 reserveY, uint256 activeId) = pair.getReservesAndId();

        // Skip if the total reserves of the pair are too low
        if (!_validateReserves(reserveX, reserveY, tokenXDecimals, tokenYDecimals)) {
            return false;
        }

        // Skip if the reserves of the _BIN_WIDTH bin around the active bin are too low
        reserveX = reserveY = 0;
        for (uint256 i = activeId - _BIN_WIDTH; i <= activeId + _BIN_WIDTH; i++) {
            (uint256 binReserveX, uint256 binReserveY) = pair.getBin(uint24(i));
            reserveX += binReserveX;
            reserveY += binReserveY;
        }

        if (!_validateReserves(reserveX, reserveY, tokenXDecimals, tokenYDecimals)) {
            return false;
        }

        return true;
    }

    /**
     * @notice Checks if the pair reserves are above the minimum threshold
     * @param reserveX The reserve of the token X
     * @param reserveY The reserve of the token Y
     * @param tokenXDecimals The decimals of the token X
     * @param tokenYDecimals The decimals of the token Y
     */
    function _validateReserves(uint256 reserveX, uint256 reserveY, uint256 tokenXDecimals, uint256 tokenYDecimals)
        private
        pure
        returns (bool isValid)
    {
        // Need at least one unit of each token in the reserves
        return reserveX > 10 ** tokenXDecimals && reserveY > 10 ** tokenYDecimals;
    }

    /**
     * @notice Return the price in collateral of a token from a V1 pair
     * @param collateral The address of the collateral (USDC or WNATIVE)
     * @param pairAddress The address of the V1 pair
     * @param tokenBase The address of the base token of the pair, i.e. the collateral one
     * @param token The address of the token
     * @return priceInCollateral The price of the token in collateral, with the collateral's decimals
     */
    function _getPriceInCollateralFromV1(address collateral, address pairAddress, address tokenBase, address token)
        private
        view
        returns (uint256 priceInCollateral)
    {
        uint256 priceInBase = _getPriceFromV1(pairAddress, token);
        uint256 priceOfBase = _getTokenWeightedAveragePrice(collateral, tokenBase);

        // Return the price with the collateral's decimals
        return (priceInBase * priceOfBase) / _PRECISION;
    }

    /**
     * @notice Return the entire TVL of a pair in token A, with `_DECIMALS` decimals
     * @dev tokenA and tokenB needs to be the two tokens paired in the given pair
     * @param pairAddress The address of the pair
     * @param tokenA The address of one of the pair's token
     * @param tokenB The address of the other pair's token
     * @return totalReserveInTokenA The total reserve of the pool in token A
     */
    function _getReserveInTokenAFromV1(address pairAddress, address tokenA, address tokenB)
        private
        view
        returns (uint256 totalReserveInTokenA)
    {
        IJoePair pair = IJoePair(pairAddress);

        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        uint8 decimals = IERC20Metadata(tokenA).decimals();

        if (tokenA < tokenB) totalReserveInTokenA = reserve0 * 2;
        else totalReserveInTokenA = reserve1 * 2;

        if (decimals < _DECIMALS) totalReserveInTokenA *= 10 ** (_DECIMALS - decimals);
        else if (decimals > _DECIMALS) totalReserveInTokenA /= 10 ** (decimals - _DECIMALS);
    }
}