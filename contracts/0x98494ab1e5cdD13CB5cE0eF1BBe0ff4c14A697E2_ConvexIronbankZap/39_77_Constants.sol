// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {INameIdentifier} from "contracts/common/Imports.sol";

abstract contract Curve3poolUnderlyerConstants {
    // underlyer addresses
    address public constant DAI_ADDRESS =
        0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC_ADDRESS =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT_ADDRESS =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;
}

abstract contract Curve3poolConstants is
    Curve3poolUnderlyerConstants,
    INameIdentifier
{
    string public constant override NAME = "curve-3pool";

    address public constant STABLE_SWAP_ADDRESS =
        0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address public constant LP_TOKEN_ADDRESS =
        0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address public constant LIQUIDITY_GAUGE_ADDRESS =
        0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A;
}