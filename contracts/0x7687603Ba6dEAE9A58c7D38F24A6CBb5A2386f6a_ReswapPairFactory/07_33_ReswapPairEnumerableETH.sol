// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ReswapPairETH} from "./ReswapPairETH.sol";
import {ReswapPairEnumerable} from "./ReswapPairEnumerable.sol";
import {IReswapPairFactoryLike} from "./IReswapPairFactoryLike.sol";

/**
    @title An NFT/Token pair where the NFT implements ERC721Enumerable, and the token is ETH
    @author boredGenius and 0xmons
 */
contract ReswapPairEnumerableETH is ReswapPairEnumerable, ReswapPairETH {
    /**
        @notice Returns the ReswapPair type
     */
    function pairVariant()
        public
        pure
        override
        returns (IReswapPairFactoryLike.PairVariant)
    {
        return IReswapPairFactoryLike.PairVariant.ENUMERABLE_ETH;
    }
}