// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../errors.sol";

abstract contract Bridge {
    uint64 public constant ETHEREUM_CHAIN_ID = 1;
    uint64 public constant OPTIMISM_CHAIN_ID = 10;
    uint64 public constant BSC_CHAIN_ID = 56;
    uint64 public constant POLYGON_CHAIN_ID = 137;
    uint64 public constant FANTOM_CHAIN_ID = 250;
    uint64 public constant ARBITRUM_ONE_CHAIN_ID = 42161;
    uint64 public constant AVALANCHE_CHAIN_ID = 43114;

    function currentChainId() internal view virtual returns (uint64) {
        return uint64(block.chainid);
    }

    modifier checkChainId(uint64 chainId) {
        if (currentChainId() == chainId) revert CannotBridgeToSameNetwork();

        if (
            chainId != ETHEREUM_CHAIN_ID &&
            chainId != OPTIMISM_CHAIN_ID &&
            chainId != BSC_CHAIN_ID &&
            chainId != POLYGON_CHAIN_ID &&
            chainId != FANTOM_CHAIN_ID &&
            chainId != ARBITRUM_ONE_CHAIN_ID &&
            chainId != AVALANCHE_CHAIN_ID
        ) revert UnsupportedDestinationChain(chainId);
        _;
    }
}