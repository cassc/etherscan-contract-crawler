// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ReswapPairETH} from "./ReswapPairETH.sol";
import {ReswapPairMissingEnumerable} from "./ReswapPairMissingEnumerable.sol";
import {IReswapPairFactoryLike} from "./IReswapPairFactoryLike.sol";

contract ReswapPairMissingEnumerableETH is
    ReswapPairMissingEnumerable,
    ReswapPairETH
{
    function pairVariant()
        public
        pure
        override
        returns (IReswapPairFactoryLike.PairVariant)
    {
        return IReswapPairFactoryLike.PairVariant.MISSING_ENUMERABLE_ETH;
    }
}