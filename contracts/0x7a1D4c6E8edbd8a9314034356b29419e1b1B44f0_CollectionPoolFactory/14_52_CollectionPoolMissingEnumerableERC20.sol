// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {CollectionPoolERC20} from "../pools/CollectionPoolERC20.sol";
import {CollectionPoolMissingEnumerable} from "./CollectionPoolMissingEnumerable.sol";
import {PoolVariant} from "./CollectionStructsAndEnums.sol";

contract CollectionPoolMissingEnumerableERC20 is CollectionPoolMissingEnumerable, CollectionPoolERC20 {
    function poolVariant() public pure override returns (PoolVariant) {
        return PoolVariant.MISSING_ENUMERABLE_ERC20;
    }
}