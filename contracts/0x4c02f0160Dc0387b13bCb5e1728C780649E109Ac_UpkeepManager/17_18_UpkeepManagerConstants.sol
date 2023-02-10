// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAggregatorV3} from "../interfaces/chainlink/IAggregatorV3.sol";
import {IUniswapRouterV3} from "../interfaces/uniswap/IUniswapRouterV3.sol";
import {IKeeperRegistry} from "../interfaces/chainlink/IKeeperRegistry.sol";
import {ILink} from "../interfaces/chainlink/ILink.sol";

abstract contract UpkeepManagerConstants {
    address internal constant KEEPER_REGISTRAR = 0xDb8e8e2ccb5C033938736aa89Fe4fa1eDfD15a1d;
    IKeeperRegistry internal constant CL_REGISTRY = IKeeperRegistry(0x02777053d6764996e594c3E88AF1D58D5363a2e6);
    address internal constant TECHOPS = 0x86cbD0ce0c087b482782c181dA8d191De18C8275;
    ILink internal constant LINK = ILink(0x514910771AF9Ca656af840dff83E8264EcF986CA);

    // CL feed oracles
    IAggregatorV3 internal constant FAST_GAS_FEED = IAggregatorV3(0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C);
    uint256 internal constant CL_FEED_HEARTBEAT_GAS = 2 hours;
    IAggregatorV3 internal constant LINK_ETH_FEED = IAggregatorV3(0xDC530D9457755926550b59e8ECcdaE7624181557);
    uint256 internal constant CL_FEED_HEARTBEAT_LINK = 6 hours;

    // uniswap v3
    IUniswapRouterV3 internal constant UNIV3_ROUTER = IUniswapRouterV3(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    // tokens involved
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 internal constant MAX_IN_BPS = 10_500;
    uint256 internal constant MIN_FUNDING_UPKEEP = 5 ether;
    uint256 internal constant REGISTRY_GAS_OVERHEAD = 80_000;
    uint256 internal constant PPB_BASE = 1_000_000_000;

    // safety constants for `setRoundsTopUp` & `setMinRoundsTopUp`
    uint256 internal constant MAX_ROUNDS_TOP_UP = 100;
    uint256 internal constant MAX_THRESHOLD_UNDER_FUNDED_TOP_UP = 10;

    // readability constant
    uint64 internal constant UINT64_MAX = type(uint64).max;
}