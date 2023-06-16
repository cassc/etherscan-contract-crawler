// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2023
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {RAY} from "@gearbox-protocol/core-v2/contracts/libraries/Constants.sol";

import {AbstractAdapter} from "../AbstractAdapter.sol";
import {AdapterType} from "../../interfaces/IAdapter.sol";

import {IUniswapV2Router02} from "../../integrations/uniswap/IUniswapV2Router02.sol";
import {IUniswapV2Adapter} from "../../interfaces/uniswap/IUniswapV2Adapter.sol";
import {UniswapConnectorChecker} from "./UniswapConnectorChecker.sol";

/// @title Uniswap V2 Router adapter interface
/// @notice Implements logic allowing CAs to perform swaps via Uniswap V2 and its forks
contract UniswapV2Adapter is AbstractAdapter, UniswapConnectorChecker, IUniswapV2Adapter {
    AdapterType public constant override _gearboxAdapterType = AdapterType.UNISWAP_V2_ROUTER;
    uint16 public constant override _gearboxAdapterVersion = 3;

    /// @notice Constructor
    /// @param _creditManager Credit manager address
    /// @param _router Uniswap V2 Router address
    constructor(address _creditManager, address _router, address[] memory _connectorTokensInit)
        AbstractAdapter(_creditManager, _router)
        UniswapConnectorChecker(_connectorTokensInit)
    {}

    /// @inheritdoc IUniswapV2Adapter
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address,
        uint256 deadline
    ) external override creditFacadeOnly {
        address creditAccount = _creditAccount(); // F: [AUV2-1]

        (bool valid, address tokenIn, address tokenOut) = _parseUniV2Path(path); // F: [AUV2-2]
        if (!valid) {
            revert InvalidPathException(); // F: [AUV2-5]
        }

        // calling `_executeSwap` because we need to check if output token is registered as collateral token in the CM
        _executeSwapSafeApprove(
            tokenIn,
            tokenOut,
            abi.encodeCall(
                IUniswapV2Router02.swapTokensForExactTokens, (amountOut, amountInMax, path, creditAccount, deadline)
            ),
            false
        ); // F: [AUV2-2]
    }

    /// @inheritdoc IUniswapV2Adapter
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address,
        uint256 deadline
    ) external override creditFacadeOnly {
        address creditAccount = _creditAccount(); // F: [AUV2-1]

        (bool valid, address tokenIn, address tokenOut) = _parseUniV2Path(path); // F: [AUV2-3]
        if (!valid) {
            revert InvalidPathException(); // F: [AUV2-5]
        }

        // calling `_executeSwap` because we need to check if output token is registered as collateral token in the CM
        _executeSwapSafeApprove(
            tokenIn,
            tokenOut,
            abi.encodeCall(
                IUniswapV2Router02.swapExactTokensForTokens, (amountIn, amountOutMin, path, creditAccount, deadline)
            ),
            false
        ); // F: [AUV2-3]
    }

    /// @inheritdoc IUniswapV2Adapter
    function swapAllTokensForTokens(uint256 rateMinRAY, address[] calldata path, uint256 deadline)
        external
        override
        creditFacadeOnly
    {
        address creditAccount = _creditAccount(); // F: [AUV2-1]

        (bool valid, address tokenIn, address tokenOut) = _parseUniV2Path(path); // F: [AUV2-4]
        if (!valid) {
            revert InvalidPathException(); // F: [AUV2-5]
        }

        uint256 balanceInBefore = IERC20(tokenIn).balanceOf(creditAccount); // F: [AUV2-4]
        if (balanceInBefore <= 1) return;

        unchecked {
            balanceInBefore--;
        }

        // calling `_executeSwap` because we need to check if output token is registered as collateral token in the CM
        _executeSwapSafeApprove(
            tokenIn,
            tokenOut,
            abi.encodeCall(
                IUniswapV2Router02.swapExactTokensForTokens,
                (balanceInBefore, (balanceInBefore * rateMinRAY) / RAY, path, creditAccount, deadline)
            ),
            true
        ); // F: [AUV2-4]
    }

    /// @dev Performs sanity check on a swap path, returns input and output tokens
    ///      - Path length must be no more than 4 (i.e., at most 3 hops)
    ///      - Each intermediary token must be a registered connector tokens
    function _parseUniV2Path(address[] memory path)
        internal
        view
        returns (bool valid, address tokenIn, address tokenOut)
    {
        uint256 len = path.length;

        valid = true;
        tokenIn = path[0];
        tokenOut = path[len - 1];

        if (len > 2) {
            valid = isConnector(path[1]);
        }

        if (valid && len > 3) {
            valid = isConnector(path[2]);
        }
        if (len > 4) {
            valid = false;
        }
    }
}