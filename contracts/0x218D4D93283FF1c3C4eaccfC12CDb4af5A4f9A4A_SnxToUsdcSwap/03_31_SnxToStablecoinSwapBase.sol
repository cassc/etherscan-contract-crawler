// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {ISwapRouter} from "./ISwapRouter.sol";
import {SwapBase} from "./SwapBase.sol";

abstract contract SnxToStablecoinSwapBase is SwapBase {
    IERC20 private constant _SNX =
        IERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F);

    uint24 private constant _SNX_STABLECOIN_FEE = 10000;

    constructor(IERC20 stablecoin) public SwapBase(_SNX, stablecoin) {} // solhint-disable-line no-empty-blocks

    function _getPath() internal view virtual override returns (bytes memory) {
        bytes memory path =
            abi.encodePacked(
                address(_IN_TOKEN),
                _SNX_STABLECOIN_FEE,
                address(_OUT_TOKEN)
            );

        return path;
    }
}