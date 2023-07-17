// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {CollectionPoolETH} from "../pools/CollectionPoolETH.sol";
import {CollectionPoolMissingEnumerable} from "./CollectionPoolMissingEnumerable.sol";
import {PoolVariant} from "./CollectionStructsAndEnums.sol";

contract CollectionPoolMissingEnumerableETH is CollectionPoolMissingEnumerable, CollectionPoolETH {
    function poolVariant() public pure override returns (PoolVariant) {
        return PoolVariant.MISSING_ENUMERABLE_ETH;
    }
}