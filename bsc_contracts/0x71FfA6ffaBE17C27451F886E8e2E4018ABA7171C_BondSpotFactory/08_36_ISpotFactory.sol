// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../spot-exchange/libraries/types/SpotFactoryStorage.sol";

interface ISpotFactory {
    event PairManagerCreated(address pairManager);

    //    function createPairManager(
    //        address quoteAsset,
    //        address baseAsset,
    //        uint256 basisPoint,
    //        uint256 BASE_BASIC_POINT,
    //        uint128 maxFindingWordsIndex,
    //        uint128 initialPip,
    //        uint64 expireTime
    //    ) external;

    function getPairManager(address quoteAsset, address baseAsset)
        external
        view
        returns (address pairManager);

    function getQuoteAndBase(address pairManager)
        external
        view
        returns (SpotFactoryStorage.Pair memory);

    function isPairManagerExist(address pairManager)
        external
        view
        returns (bool);

    function getPairManagerSupported(address tokenA, address tokenB)
        external
        view
        returns (
            address baseToken,
            address quoteToken,
            address pairManager
        );
}