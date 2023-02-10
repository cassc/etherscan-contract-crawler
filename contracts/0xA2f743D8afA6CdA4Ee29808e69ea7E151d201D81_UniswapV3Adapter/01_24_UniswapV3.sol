// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
pragma abicoder v2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { AbstractAdapter } from "@gearbox-protocol/core-v2/contracts/adapters/AbstractAdapter.sol";
import { UniswapConnectorChecker } from "./UniswapConnectorChecker.sol";
import { IPoolService } from "@gearbox-protocol/core-v2/contracts/interfaces/IPoolService.sol";
import { ICreditManagerV2 } from "@gearbox-protocol/core-v2/contracts/interfaces/ICreditManagerV2.sol";

import { IUniswapV3Adapter } from "../../interfaces/uniswap/IUniswapV3Adapter.sol";
import { IUniswapPathChecker } from "../../interfaces/uniswap/IUniswapPathChecker.sol";
import { AdapterType } from "@gearbox-protocol/core-v2/contracts/interfaces/adapters/IAdapter.sol";
import { ISwapRouter } from "../../integrations/uniswap/IUniswapV3.sol";
import { Path } from "../../integrations/uniswap/Path.sol";

import { RAY } from "@gearbox-protocol/core-v2/contracts/libraries/Constants.sol";

/// @dev The length of the bytes encoded address
uint256 constant ADDR_SIZE = 20;

/// @dev The length of the uint24 encoded address
uint256 constant FEE_SIZE = 3;

/// @dev Minimal path length in bytes
uint256 constant MIN_PATH_LENGTH = 2 * ADDR_SIZE + FEE_SIZE;

/// @dev Number of bytes in path per single token
uint256 constant ADDR_PLUS_FEE_LENGTH = ADDR_SIZE + FEE_SIZE;

/// @dev Maximal allowed path length in bytes (3 hops)
uint256 constant MAX_PATH_LENGTH = 4 * ADDR_SIZE + 3 * FEE_SIZE;

/// @title UniswapV3 Router adapter
contract UniswapV3Adapter is
    AbstractAdapter,
    UniswapConnectorChecker,
    IUniswapV3Adapter,
    ReentrancyGuard
{
    using Path for bytes;

    AdapterType public constant _gearboxAdapterType =
        AdapterType.UNISWAP_V3_ROUTER;
    uint16 public constant _gearboxAdapterVersion = 2;

    /// @dev Constructor
    /// @param _creditManager Address Credit manager
    /// @param _router Address of ISwapRouter
    constructor(
        address _creditManager,
        address _router,
        address[] memory _connectorTokensInit
    )
        AbstractAdapter(_creditManager, _router)
        UniswapConnectorChecker(_connectorTokensInit)
    {}

    /// @notice Sends an order to swap `amountIn` of one token for as much as possible of another token
    /// - Makes a max allowance fast check call, replacing the recipient with the Credit Account
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        override
        nonReentrant
        returns (uint256 amountOut)
    {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[AUV3-1]

        ExactInputSingleParams memory paramsUpdate = params; // F:[AUV3-2,10]
        paramsUpdate.recipient = creditAccount; // F:[AUV3-2,10]

        amountOut = abi.decode(
            _executeMaxAllowanceFastCheck(
                creditAccount,
                params.tokenIn,
                params.tokenOut,
                abi.encodeWithSelector(
                    ISwapRouter.exactInputSingle.selector,
                    paramsUpdate
                ),
                true,
                false
            ),
            (uint256)
        ); // F:[AUV2-2,10]
    }

    /// @notice Sends an order to swap the entire balance of one token for as much as possible of another token
    /// - Fills the `ExactInputSingleParams` struct
    /// - Makes a max allowance fast check call, passing the new struct as params
    /// @param params The parameters necessary for the swap, encoded as `ExactAllInputSingleParams` in calldata
    /// `ExactAllInputSingleParams` has the following fields:
    /// - tokenIn - same as normal params
    /// - tokenOut - same as normal params
    /// - fee - same as normal params
    /// - deadline - same as normal params
    /// - rateMinRAY - Minimal exchange rate between the input and the output tokens
    /// - sqrtPriceLimitX96 - same as normal params
    /// @return amountOut The amount of the received token
    function exactAllInputSingle(ExactAllInputSingleParams calldata params)
        external
        returns (uint256 amountOut)
    {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[AUV3-1]

        uint256 balanceInBefore = IERC20(params.tokenIn).balanceOf(
            creditAccount
        ); // F:[AUV3-3]

        // We keep 1 on tokenIn balance for gas efficiency
        if (balanceInBefore > 1) {
            unchecked {
                balanceInBefore--;
            }

            ExactInputSingleParams
                memory paramsUpdate = ExactInputSingleParams({
                    tokenIn: params.tokenIn,
                    tokenOut: params.tokenOut,
                    fee: params.fee,
                    recipient: creditAccount,
                    deadline: params.deadline,
                    amountIn: balanceInBefore,
                    amountOutMinimum: (balanceInBefore * params.rateMinRAY) /
                        RAY,
                    sqrtPriceLimitX96: params.sqrtPriceLimitX96
                }); // F:[AUV3-3]

            amountOut = abi.decode(
                _executeMaxAllowanceFastCheck(
                    creditAccount,
                    params.tokenIn,
                    params.tokenOut,
                    abi.encodeWithSelector(
                        ISwapRouter.exactInputSingle.selector,
                        paramsUpdate
                    ),
                    true,
                    true
                ),
                (uint256)
            ); // F:[AUV3-3]
        }
    }

    /// @notice Sends an order to swap `amountIn` of one token for as much as possible of another along the specified path
    /// - Makes a max allowance fast check call, replacing the recipient with the Credit Account
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params)
        external
        payable
        override
        nonReentrant
        returns (uint256 amountOut)
    {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[AUV3-1]

        (bool valid, address tokenIn, address tokenOut) = _parseUniV3Path(
            params.path
        );

        if (!valid) {
            revert InvalidPathException();
        }

        ExactInputParams memory paramsUpdate = params; // F:[AUV3-4]
        paramsUpdate.recipient = creditAccount; // F:[AUV3-4]

        amountOut = abi.decode(
            _executeMaxAllowanceFastCheck(
                creditAccount,
                tokenIn,
                tokenOut,
                abi.encodeWithSelector(
                    ISwapRouter.exactInput.selector,
                    paramsUpdate
                ),
                true,
                false
            ),
            (uint256)
        ); // F:[AUV3-4]
    }

    /// @notice Swaps the entire balance of one token for as much as possible of another along the specified path
    /// - Fills the `ExactAllInputParams` struct
    /// - Makes a max allowance fast check call, passing the new struct as `params`
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactAllInputParams` in calldata
    /// `ExactAllInputParams` has the following fields:
    /// - path - same as normal params
    /// - deadline - same as normal params
    /// - rateMinRAY - minimal exchange rate between the input and the output tokens
    /// @return amountOut The amount of the received token
    function exactAllInput(ExactAllInputParams calldata params)
        external
        returns (uint256 amountOut)
    {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[AUV3-1]

        (bool valid, address tokenIn, address tokenOut) = _parseUniV3Path(
            params.path
        );

        if (!valid) {
            revert InvalidPathException();
        }

        uint256 balanceInBefore = IERC20(tokenIn).balanceOf(creditAccount); // F:[AUV3-5]

        // We keep 1 on tokenIn balance for gas efficiency
        if (balanceInBefore > 1) {
            unchecked {
                balanceInBefore--;
            }
            ExactInputParams memory paramsUpdate = ExactInputParams({
                path: params.path,
                recipient: creditAccount,
                deadline: params.deadline,
                amountIn: balanceInBefore,
                amountOutMinimum: (balanceInBefore * params.rateMinRAY) / RAY
            }); // F:[AUV3-5]

            amountOut = abi.decode(
                _executeMaxAllowanceFastCheck(
                    creditAccount,
                    tokenIn,
                    tokenOut,
                    abi.encodeWithSelector(
                        ISwapRouter.exactInput.selector,
                        paramsUpdate
                    ),
                    true,
                    true
                ),
                (uint256)
            ); // F:[AUV3-5]
        }
    }

    /// @notice Sends an order to swap as little as possible of one token for `amountOut` of another token
    /// - Makes a max allowance fast check call, replacing the recipient with the Credit Account
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        override
        nonReentrant
        returns (uint256 amountIn)
    {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[AUV3-1]

        ExactOutputSingleParams memory paramsUpdate = params; // F:[AUV3-6]
        paramsUpdate.recipient = creditAccount; // F:[AUV3-6]

        amountIn = abi.decode(
            _executeMaxAllowanceFastCheck(
                creditAccount,
                paramsUpdate.tokenIn,
                paramsUpdate.tokenOut,
                abi.encodeWithSelector(
                    ISwapRouter.exactOutputSingle.selector,
                    paramsUpdate
                ),
                true,
                false
            ),
            (uint256)
        ); // F:[AUV3-6]
    }

    /// @notice Sends an order to swap as little as possible of one token for
    /// `amountOut` of another along the specified path (reversed)
    /// - Makes a max allowance fast check call, replacing the recipient with the Credit Account
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        override
        nonReentrant
        returns (uint256 amountIn)
    {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[AUV3-1]

        (bool valid, address tokenOut, address tokenIn) = _parseUniV3Path(
            params.path
        );

        if (!valid) {
            revert InvalidPathException();
        }

        ExactOutputParams memory paramsUpdate = params; // F:[AUV3-7]
        paramsUpdate.recipient = creditAccount; // F:[AUV3-7]

        amountIn = abi.decode(
            _executeMaxAllowanceFastCheck(
                creditAccount,
                tokenIn,
                tokenOut,
                abi.encodeWithSelector(
                    ISwapRouter.exactOutput.selector,
                    paramsUpdate
                ),
                true,
                false
            ),
            (uint256)
        ); // F:[AUV3-7]
    }

    /// @dev Performs sanity checks on a Uniswap V3 path and returns the input and output tokens
    /// @param path Path to check
    /// @notice Sanity checks include path length not being more than 3 hops and intermediary tokens
    ///         being allowed as connectors
    function _parseUniV3Path(bytes memory path)
        internal
        view
        returns (
            bool valid,
            address tokenIn,
            address tokenOut
        )
    {
        valid = true;

        if (path.length < MIN_PATH_LENGTH || path.length > MAX_PATH_LENGTH)
            valid = false;

        (tokenIn, , ) = path.decodeFirstPool();

        while (path.hasMultiplePools()) {
            (, address midToken, ) = path.decodeFirstPool();

            if (!isConnector(midToken)) {
                valid = false;
            }

            path = path.skipToken();
        }

        (, tokenOut, ) = path.decodeFirstPool();
    }
}