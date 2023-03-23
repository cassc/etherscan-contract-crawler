// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IWETH} from "../interfaces/IWETH.sol";

struct RouterParameters {
    address weth;
    address balancerRouter;
    address bancorRouter;
    address uniswapV2Factory;
    address uniswapV3Factory;
    address sushiswapRouter;
    address pancakeswapRouter;
    address shibaswapRouter;
    address hyphenBridge;
    address celerBridge;
    address hopEthBridge;
    address hopUsdcBridge;
    address hopUsdtBridge;
    address hopDaiBridge;
    address hopWbtcBridge;
    address hopMaticBridge;
    address acrossBridge;
    address multichainEthBridge;
    address multichainErc20Bridge;
    address synapseBridge;
    address allBridge;
    address portalBridge;
    address optimismBridge;
    address polygonPosBridge;
    address polygonApproveAddr;
    address omniBridge;
}

contract RouterImmutables {
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant _MIN_SQRT_RATIO = 4295128739 + 1;

    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant _MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342 - 1;

    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    IWETH internal immutable WETH;

    address internal immutable BALANCER_ROUTER;

    address internal immutable BANCOR_ROUTER;

    address internal immutable UNISWAP_V2_FACTORY;

    address internal immutable UNISWAP_V3_FACTORY;

    address internal immutable SUSHISWAP_ROUTER;

    address internal immutable PANCAKESWAP_ROUTER;

    address internal immutable SHIBASWAP_ROUTER;

    address internal immutable HYPHEN_BRIDGE;

    address internal immutable CELER_BRIDGE;

    address internal immutable HOP_ETH_BRIDGE;

    address internal immutable HOP_USDC_BRIDGE;

    address internal immutable HOP_USDT_BRIDGE;

    address internal immutable HOP_DAI_BRIDGE;

    address internal immutable HOP_WBTC_BRIDGE;

    address internal immutable HOP_MATIC_BRIDGE;

    address internal immutable ACROSS_BRIDGE;

    address internal immutable MULTICHAIN_ETH_BRIDGE;

    address internal immutable MULTICHAIN_ERC20_BRIDGE;

    address internal immutable SYNAPSE_BRIDGE;

    address internal immutable ALL_BRIDGE;

    address internal immutable PORTAL_BRIDGE;

    address internal immutable OPTIMISM_BRIDGE;

    address internal immutable POLYGON_POS_BRIDGE;

    address internal immutable POLYGON_APPROVE_ADDR;

    address internal immutable OMNI_BRIDGE;

    constructor(RouterParameters memory params) {
        WETH = IWETH(params.weth);
        BALANCER_ROUTER = params.balancerRouter;
        BANCOR_ROUTER = params.bancorRouter;
        UNISWAP_V2_FACTORY = params.uniswapV2Factory;
        UNISWAP_V3_FACTORY = params.uniswapV3Factory;
        SUSHISWAP_ROUTER = params.sushiswapRouter;
        PANCAKESWAP_ROUTER = params.pancakeswapRouter;
        SHIBASWAP_ROUTER = params.shibaswapRouter;
        HYPHEN_BRIDGE = params.hyphenBridge;
        CELER_BRIDGE = params.celerBridge;
        HOP_ETH_BRIDGE = params.hopEthBridge;
        HOP_USDC_BRIDGE = params.hopUsdcBridge;
        HOP_USDT_BRIDGE = params.hopUsdtBridge;
        HOP_DAI_BRIDGE = params.hopDaiBridge;
        HOP_WBTC_BRIDGE = params.hopWbtcBridge;
        HOP_MATIC_BRIDGE = params.hopMaticBridge;
        ACROSS_BRIDGE = params.acrossBridge;
        MULTICHAIN_ETH_BRIDGE = params.multichainEthBridge;
        MULTICHAIN_ERC20_BRIDGE = params.multichainErc20Bridge;
        SYNAPSE_BRIDGE = params.synapseBridge;
        ALL_BRIDGE = params.allBridge;
        PORTAL_BRIDGE = params.portalBridge;
        OPTIMISM_BRIDGE = params.optimismBridge;
        POLYGON_POS_BRIDGE = params.polygonPosBridge;
        POLYGON_APPROVE_ADDR = params.polygonApproveAddr;
        OMNI_BRIDGE = params.omniBridge;
    }
}