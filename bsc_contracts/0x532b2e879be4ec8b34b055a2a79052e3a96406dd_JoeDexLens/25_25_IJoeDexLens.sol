// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {IJoeFactory} from "joe-v2/interfaces/IJoeFactory.sol";
import {ILBFactory} from "joe-v2/interfaces/ILBFactory.sol";
import {ILBLegacyFactory} from "joe-v2/interfaces/ILBLegacyFactory.sol";
import {ILBLegacyRouter} from "joe-v2/interfaces/ILBLegacyRouter.sol";
import {ILBRouter} from "joe-v2/interfaces/ILBRouter.sol";
import {ISafeAccessControlEnumerable} from "solrary/access/ISafeAccessControlEnumerable.sol";

import {AggregatorV3Interface} from "../interfaces/AggregatorV3Interface.sol";

/// @title Interface of the Joe Dex Lens contract
/// @author Trader Joe
/// @notice The interface needed to interract with the Joe Dex Lens contract
interface IJoeDexLens is ISafeAccessControlEnumerable {
    error JoeDexLens__UnknownDataFeedType();
    error JoeDexLens__CollateralNotInPair(address pair, address collateral);
    error JoeDexLens__TokenNotInPair(address pair, address token);
    error JoeDexLens__SameTokens();
    error JoeDexLens__DataFeedAlreadyAdded(address colateral, address token, address dataFeed);
    error JoeDexLens__DataFeedNotInSet(address colateral, address token, address dataFeed);
    error JoeDexLens__LengthsMismatch();
    error JoeDexLens__NullWeight();
    error JoeDexLens__WrongPair();
    error JoeDexLens__InvalidChainLinkPrice();
    error JoeDexLens__NotEnoughLiquidity();
    error JoeDexLens__V1ContractNotSet();
    error JoeDexLens__V2ContractNotSet();
    error JoeDexLens__V2_1ContractNotSet();
    error JoeDexLens__LBV2_1AddressMismatch();
    error JoeDexLens__LBV2AddressMismatch();
    error JoeDexLens__JoeV1AddressMismatch();
    error JoeDexLens__WNativeMismatch();
    error JoeDexLens__ZeroAddress();

    /// @notice Enumerators of the different data feed types
    enum dfType {
        V1,
        V2,
        V2_1,
        CHAINLINK
    }

    /// @notice Structure for data feeds, contains the data feed's address and its type.
    /// For V1/V2, the`dfAddress` should be the address of the pair
    /// For chainlink, the `dfAddress` should be the address of the aggregator
    struct DataFeed {
        address dfAddress;
        uint88 dfWeight;
        dfType dfType;
    }

    /// @notice Structure for a set of data feeds
    /// `datafeeds` is the list of addresses of all the data feeds
    /// `indexes` is a mapping linking the address of a data feed to its index in the `datafeeds` list.
    struct DataFeedSet {
        DataFeed[] dataFeeds;
        mapping(address => uint256) indexes;
    }

    event DataFeedAdded(address collateral, address token, DataFeed dataFeed);

    event DataFeedsWeightSet(address collateral, address token, address dfAddress, uint256 weight);

    event DataFeedRemoved(address collateral, address token, address dfAddress);

    function getWNative() external view returns (address wNative);

    function getUSDStableCoin() external view returns (address usd);

    function getLegacyRouterV2() external view returns (ILBLegacyRouter legacyRouterV2);

    function getRouterV2() external view returns (ILBRouter routerV2);

    function getFactoryV1() external view returns (IJoeFactory factoryV1);

    function getLegacyFactoryV2() external view returns (ILBLegacyFactory legacyFactoryV2);

    function getFactoryV2() external view returns (ILBFactory factoryV2);

    function getUSDDataFeeds(address token) external view returns (DataFeed[] memory dataFeeds);

    function getNativeDataFeeds(address token) external view returns (DataFeed[] memory dataFeeds);

    function getTokenPriceUSD(address token) external view returns (uint256 price);

    function getTokenPriceNative(address token) external view returns (uint256 price);

    function getTokensPricesUSD(address[] calldata tokens) external view returns (uint256[] memory prices);

    function getTokensPricesNative(address[] calldata tokens) external view returns (uint256[] memory prices);

    function addUSDDataFeed(address token, DataFeed calldata dataFeed) external;

    function addNativeDataFeed(address token, DataFeed calldata dataFeed) external;

    function setUSDDataFeedWeight(address token, address dfAddress, uint88 newWeight) external;

    function setNativeDataFeedWeight(address token, address dfAddress, uint88 newWeight) external;

    function removeUSDDataFeed(address token, address dfAddress) external;

    function removeNativeDataFeed(address token, address dfAddress) external;

    function addUSDDataFeeds(address[] calldata tokens, DataFeed[] calldata dataFeeds) external;

    function addNativeDataFeeds(address[] calldata tokens, DataFeed[] calldata dataFeeds) external;

    function setUSDDataFeedsWeights(
        address[] calldata _tokens,
        address[] calldata _dfAddresses,
        uint88[] calldata _newWeights
    ) external;

    function setNativeDataFeedsWeights(
        address[] calldata _tokens,
        address[] calldata _dfAddresses,
        uint88[] calldata _newWeights
    ) external;

    function removeUSDDataFeeds(address[] calldata tokens, address[] calldata dfAddresses) external;

    function removeNativeDataFeeds(address[] calldata tokens, address[] calldata dfAddresses) external;
}