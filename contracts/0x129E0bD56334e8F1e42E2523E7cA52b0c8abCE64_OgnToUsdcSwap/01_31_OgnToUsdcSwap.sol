// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {OgnToStablecoinSwapBase} from "./OgnToStablecoinSwapBase.sol";

contract OgnToUsdcSwap is OgnToStablecoinSwapBase {
    string public constant override NAME = "ogn-to-usdc";

    IERC20 private constant _USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    // solhint-disable-next-line no-empty-blocks
    constructor() public OgnToStablecoinSwapBase(_USDC) {}
}