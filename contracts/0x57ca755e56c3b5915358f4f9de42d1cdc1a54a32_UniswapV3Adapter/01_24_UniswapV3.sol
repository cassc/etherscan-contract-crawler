// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2023
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {RAY} from "@gearbox-protocol/core-v2/contracts/libraries/Constants.sol";

import {AbstractAdapter} from "../AbstractAdapter.sol";
import {AdapterType} from "../../interfaces/IAdapter.sol";

import {ISwapRouter} from "../../integrations/uniswap/IUniswapV3.sol";
import {BytesLib} from "../../integrations/uniswap/BytesLib.sol";
import {IUniswapV3Adapter} from "../../interfaces/uniswap/IUniswapV3Adapter.sol";
import {UniswapConnectorChecker} from "./UniswapConnectorChecker.sol";

/// @title Uniswap V3 Router adapter interface
/// @notice Implements logic allowing CAs to perform swaps via Uniswap V3
contract UniswapV3Adapter is AbstractAdapter, UniswapConnectorChecker, IUniswapV3Adapter {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;

    /// @dev The length of the uint24 encoded address
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;

    /// @dev The length of the path with 1 hop
    uint256 private constant PATH_2_LENGTH = 2 * ADDR_SIZE + FEE_SIZE;

    /// @dev The length of the path with 2 hops
    uint256 private constant PATH_3_LENGTH = 3 * ADDR_SIZE + 2 * FEE_SIZE;

    /// @dev The length of the path with 3 hops
    uint256 private constant PATH_4_LENGTH = 4 * ADDR_SIZE + 3 * FEE_SIZE;

    AdapterType public constant override _gearboxAdapterType = AdapterType.UNISWAP_V3_ROUTER;
    uint16 public constant override _gearboxAdapterVersion = 3;

    /// @notice Constructor
    /// @param _creditManager Credit manager address
    /// @param _router Uniswap V3 Router address
    constructor(address _creditManager, address _router, address[] memory _connectorTokensInit)
        AbstractAdapter(_creditManager, _router)
        UniswapConnectorChecker(_connectorTokensInit)
    {}

    /// @inheritdoc IUniswapV3Adapter
    function exactInputSingle(ISwapRouter.ExactInputSingleParams calldata params) external override creditFacadeOnly {
        address creditAccount = _creditAccount(); // F: [AUV3-1]

        ISwapRouter.ExactInputSingleParams memory paramsUpdate = params; // F: [AUV3-2]
        paramsUpdate.recipient = creditAccount; // F: [AUV3-2]

        // calling `_executeSwap` because we need to check if output token is registered as collateral token in the CM
        _executeSwapSafeApprove(
            params.tokenIn, params.tokenOut, abi.encodeCall(ISwapRouter.exactInputSingle, (paramsUpdate)), false
        ); // F: [AUV3-2]
    }

    /// @inheritdoc IUniswapV3Adapter
    function exactAllInputSingle(ExactAllInputSingleParams calldata params) external override creditFacadeOnly {
        address creditAccount = _creditAccount(); // F: [AUV3-1]

        uint256 balanceInBefore = IERC20(params.tokenIn).balanceOf(creditAccount); // F: [AUV3-3]
        if (balanceInBefore <= 1) return;

        unchecked {
            balanceInBefore--;
        }

        ISwapRouter.ExactInputSingleParams memory paramsUpdate = ISwapRouter.ExactInputSingleParams({
            tokenIn: params.tokenIn,
            tokenOut: params.tokenOut,
            fee: params.fee,
            recipient: creditAccount,
            deadline: params.deadline,
            amountIn: balanceInBefore,
            amountOutMinimum: (balanceInBefore * params.rateMinRAY) / RAY,
            sqrtPriceLimitX96: params.sqrtPriceLimitX96
        }); // F: [AUV3-3]

        // calling `_executeSwap` because we need to check if output token is registered as collateral token in the CM
        _executeSwapSafeApprove(
            params.tokenIn, params.tokenOut, abi.encodeCall(ISwapRouter.exactInputSingle, (paramsUpdate)), true
        ); // F: [AUV3-3]
    }

    /// @inheritdoc IUniswapV3Adapter
    function exactInput(ISwapRouter.ExactInputParams calldata params) external override creditFacadeOnly {
        address creditAccount = _creditAccount(); // F: [AUV3-1]

        (bool valid, address tokenIn, address tokenOut) = _parseUniV3Path(params.path);
        if (!valid) {
            revert InvalidPathException(); // F: [AUV3-9]
        }

        ISwapRouter.ExactInputParams memory paramsUpdate = params; // F: [AUV3-4]
        paramsUpdate.recipient = creditAccount; // F: [AUV3-4]

        // calling `_executeSwap` because we need to check if output token is registered as collateral token in the CM
        _executeSwapSafeApprove(tokenIn, tokenOut, abi.encodeCall(ISwapRouter.exactInput, (paramsUpdate)), false); // F: [AUV3-4]
    }

    /// @inheritdoc IUniswapV3Adapter
    function exactAllInput(ExactAllInputParams calldata params) external override creditFacadeOnly {
        address creditAccount = _creditAccount(); // F: [AUV3-1]

        (bool valid, address tokenIn, address tokenOut) = _parseUniV3Path(params.path);
        if (!valid) {
            revert InvalidPathException(); // F: [AUV3-9]
        }

        uint256 balanceInBefore = IERC20(tokenIn).balanceOf(creditAccount); // F: [AUV3-5]
        if (balanceInBefore <= 1) return;

        unchecked {
            balanceInBefore--;
        }
        ISwapRouter.ExactInputParams memory paramsUpdate = ISwapRouter.ExactInputParams({
            path: params.path,
            recipient: creditAccount,
            deadline: params.deadline,
            amountIn: balanceInBefore,
            amountOutMinimum: (balanceInBefore * params.rateMinRAY) / RAY
        }); // F: [AUV3-5]

        // calling `_executeSwap` because we need to check if output token is registered as collateral token in the CM
        _executeSwapSafeApprove(tokenIn, tokenOut, abi.encodeCall(ISwapRouter.exactInput, (paramsUpdate)), true); // F: [AUV3-5]
    }

    /// @inheritdoc IUniswapV3Adapter
    function exactOutputSingle(ISwapRouter.ExactOutputSingleParams calldata params)
        external
        override
        creditFacadeOnly
    {
        address creditAccount = _creditAccount(); // F: [AUV3-1]

        ISwapRouter.ExactOutputSingleParams memory paramsUpdate = params; // F: [AUV3-6]
        paramsUpdate.recipient = creditAccount; // F: [AUV3-6]

        // calling `_executeSwap` because we need to check if output token is registered as collateral token in the CM
        _executeSwapSafeApprove(
            params.tokenIn, params.tokenOut, abi.encodeCall(ISwapRouter.exactOutputSingle, (paramsUpdate)), false
        ); // F: [AUV3-6]
    }

    /// @inheritdoc IUniswapV3Adapter
    function exactOutput(ISwapRouter.ExactOutputParams calldata params) external override creditFacadeOnly {
        address creditAccount = _creditAccount(); // F: [AUV3-1]

        (bool valid, address tokenOut, address tokenIn) = _parseUniV3Path(params.path);
        if (!valid) {
            revert InvalidPathException(); // F: [AUV3-9]
        }

        ISwapRouter.ExactOutputParams memory paramsUpdate = params; // F: [AUV3-7]
        paramsUpdate.recipient = creditAccount; // F: [AUV3-7]

        // calling `_executeSwap` because we need to check if output token is registered as collateral token in the CM
        _executeSwapSafeApprove(tokenIn, tokenOut, abi.encodeCall(ISwapRouter.exactOutput, (paramsUpdate)), false); // F: [AUV3-7]
    }

    /// @dev Performs sanity check on a swap path, returns input and output tokens
    ///      - Path length must be no more than 4 (i.e., at most 3 hops)
    ///      - Each intermediary token must be a registered connector tokens
    function _parseUniV3Path(bytes memory path) internal view returns (bool valid, address tokenIn, address tokenOut) {
        uint256 len = path.length;

        if (len == PATH_2_LENGTH) {
            return (true, path.toAddress(0), path.toAddress(NEXT_OFFSET));
        }

        if (len == PATH_3_LENGTH) {
            valid = isConnector(path.toAddress(NEXT_OFFSET));
            return (valid, path.toAddress(0), path.toAddress(2 * NEXT_OFFSET));
        }

        if (len == PATH_4_LENGTH) {
            valid = isConnector(path.toAddress(NEXT_OFFSET)) && isConnector(path.toAddress(2 * NEXT_OFFSET));
            return (valid, path.toAddress(0), path.toAddress(3 * NEXT_OFFSET));
        }
    }
}