// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {ISwapRouter} from "./ISwapRouter.sol";
import {SwapBase} from "./SwapBase.sol";

abstract contract OgnToStablecoinSwapBase is SwapBase {
    IERC20 private constant _OGN =
        IERC20(0x8207c1FfC5B6804F6024322CcF34F29c3541Ae26);
    IERC20 private constant _WETH =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    uint24 private constant _OGN_WETH_FEE = 3000;
    uint24 private constant _WETH_STABLECOIN_FEE = 500;

    constructor(IERC20 stablecoin) public SwapBase(_OGN, stablecoin) {} // solhint-disable-line no-empty-blocks

    function _getPath() internal view virtual override returns (bytes memory) {
        bytes memory path =
            abi.encodePacked(
                address(_IN_TOKEN),
                _OGN_WETH_FEE,
                address(_WETH),
                _WETH_STABLECOIN_FEE,
                address(_OUT_TOKEN)
            );

        return path;
    }
}