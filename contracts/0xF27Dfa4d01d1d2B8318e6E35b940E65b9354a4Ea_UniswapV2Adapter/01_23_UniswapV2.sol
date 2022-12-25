// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { AbstractAdapter } from "@gearbox-protocol/core-v2/contracts/adapters/AbstractAdapter.sol";
import { UniswapConnectorChecker } from "./UniswapConnectorChecker.sol";
import { IPoolService } from "@gearbox-protocol/core-v2/contracts/interfaces/IPoolService.sol";
import { ICreditManagerV2 } from "@gearbox-protocol/core-v2/contracts/interfaces/ICreditManagerV2.sol";

import { IUniswapV2Router02 } from "../../integrations/uniswap/IUniswapV2Router02.sol";
import { IUniswapV2Adapter } from "../../interfaces/uniswap/IUniswapV2Adapter.sol";
import { IAdapter, AdapterType } from "@gearbox-protocol/core-v2/contracts/interfaces/adapters/IAdapter.sol";
import { IUniswapPathChecker } from "../../interfaces/uniswap/IUniswapPathChecker.sol";

import { RAY } from "@gearbox-protocol/core-v2/contracts/libraries/Constants.sol";

// EXCEPTIONS
import { NotImplementedException } from "@gearbox-protocol/core-v2/contracts/interfaces/IErrors.sol";

/// @title UniswapV2 Router adapter
contract UniswapV2Adapter is
    AbstractAdapter,
    UniswapConnectorChecker,
    IUniswapV2Adapter,
    ReentrancyGuard
{
    AdapterType public constant _gearboxAdapterType =
        AdapterType.UNISWAP_V2_ROUTER;
    uint16 public constant _gearboxAdapterVersion = 2;

    /// @dev Constructor
    /// @param _creditManager Address Credit manager
    /// @param _router Address of IUniswapV2Router02
    constructor(
        address _creditManager,
        address _router,
        address[] memory _connectorTokensInit
    )
        AbstractAdapter(_creditManager, _router)
        UniswapConnectorChecker(_connectorTokensInit)
    {}

    /**
     * @dev Sends an order to swap tokens to exact tokens using a Uniswap-compatible protocol
     * - Makes a max allowance fast check call to target, replacing the `to` parameter with the CA address
     * @param amountOut The amount of output tokens to receive.
     * @param amountInMax The maximum amount of input tokens that can be required before the transaction reverts.
     * @param path An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of
     *        addresses must exist and have liquidity.
     * @param deadline Unix timestamp after which the transaction will revert.
     * for more information, see: https://uniswap.org/docs/v2/smart-contracts/router02/
     * @notice `to` is ignored, since it is forbidden to transfer funds from a CA
     * @notice Fast check parameters:
     * Input token: First token in the path
     * Output token: Last token in the path
     * Input token is allowed, since the target does a transferFrom for the input token
     * The input token does not need to be disabled, because this does not spend the entire
     * balance, generally
     */
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address,
        uint256 deadline
    ) external override nonReentrant returns (uint256[] memory amounts) {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[AUV2-1]

        (bool valid, address tokenIn, address tokenOut) = _parseUniV2Path(path); // F:[AUV2-2, UPC-3]

        if (!valid) {
            revert InvalidPathException(); // F:[AUV2-10]
        }

        amounts = abi.decode(
            _executeMaxAllowanceFastCheck(
                creditAccount,
                tokenIn,
                tokenOut,
                abi.encodeWithSelector(
                    IUniswapV2Router02.swapTokensForExactTokens.selector,
                    amountOut,
                    amountInMax,
                    path,
                    creditAccount,
                    deadline
                ),
                true,
                false
            ),
            (uint256[])
        ); // F:[AUV2-2]
    }

    /**
     * @dev Sends an order to swap an exact amount of token to another token using a Uniswap-compatible protocol
     * - Makes a max allowance fast check call to target, replacing the `to` parameter with the CA address
     * @param amountIn The amount of input tokens to send.
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param path An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of
     *        addresses must exist and have liquidity.
     * @param deadline Unix timestamp after which the transaction will revert.
     * for more information, see: https://uniswap.org/docs/v2/smart-contracts/router02/
     * @notice `to` is ignored, since it is forbidden to transfer funds from a CA
     * @notice Fast check parameters:
     * Input token: First token in the path
     * Output token: Last token in the path
     * Input token is allowed, since the target does a transferFrom for the input token
     * The input token does not need to be disabled, because this does not spend the entire
     * balance, generally
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address,
        uint256 deadline
    ) external override nonReentrant returns (uint256[] memory amounts) {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[AUV2-1]

        (bool valid, address tokenIn, address tokenOut) = _parseUniV2Path(path); // F:[AUV2-3, UPC-3]

        if (!valid) {
            revert InvalidPathException(); // F:[AUV2-10]
        }

        amounts = abi.decode(
            _executeMaxAllowanceFastCheck(
                creditAccount,
                tokenIn,
                tokenOut,
                abi.encodeWithSelector(
                    IUniswapV2Router02.swapExactTokensForTokens.selector,
                    amountIn,
                    amountOutMin,
                    path,
                    creditAccount,
                    deadline
                ),
                true,
                false
            ),
            (uint256[])
        ); // F:[AUV2-3]
    }

    /**
     * @dev Sends an order to swap the entire token balance to another token using a Uniswap-compatible protocol
     * - Makes a max allowance fast check call to target, replacing the `to` parameter with the CA address
     * @param rateMinRAY The minimal exchange rate between the input and the output tokens.
     * @param path An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of
     *        addresses must exist and have liquidity.
     * @param deadline Unix timestamp after which the transaction will revert.
     * for more information, see: https://uniswap.org/docs/v2/smart-contracts/router02/
     * @notice Under the hood, calls swapExactTokensForTokens, passing balance minus 1 as the amount
     * @notice Fast check parameters:
     * Input token: First token in the path
     * Output token: Last token in the path
     * Input token is allowed, since the target does a transferFrom for the input token
     * The input token does need to be disabled, because this spends the entire balance
     */
    function swapAllTokensForTokens(
        uint256 rateMinRAY,
        address[] calldata path,
        uint256 deadline
    ) external override nonReentrant returns (uint256[] memory amounts) {
        address creditAccount = creditManager.getCreditAccountOrRevert(
            msg.sender
        ); // F:[AUV2-1]

        address tokenIn;
        address tokenOut;

        {
            bool valid;
            (valid, tokenIn, tokenOut) = _parseUniV2Path(path); // F:[AUV2-4, UPC-3]

            if (!valid) {
                revert InvalidPathException(); // F:[AUV2-10]
            }
        }

        uint256 balanceInBefore = IERC20(tokenIn).balanceOf(creditAccount); // F:[AUV2-4]

        if (balanceInBefore > 1) {
            unchecked {
                balanceInBefore--;
            }

            amounts = abi.decode(
                _executeMaxAllowanceFastCheck(
                    creditAccount,
                    tokenIn,
                    tokenOut,
                    abi.encodeWithSelector(
                        IUniswapV2Router02.swapExactTokensForTokens.selector,
                        balanceInBefore,
                        (balanceInBefore * rateMinRAY) / RAY,
                        path,
                        creditAccount,
                        deadline
                    ),
                    true,
                    true
                ),
                (uint256[])
            ); // F:[AUV2-4]
        }
    }

    /// @dev Not implemented, as native ETH is not supported
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address, // token,
        uint256, // liquidity,
        uint256, // amountTokenMin,
        uint256, // amountETHMin,
        address, // to,
        uint256 // deadline
    ) external pure override returns (uint256) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, as native ETH is not supported
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address, // token,
        uint256, // liquidity,
        uint256, // amountTokenMin,
        uint256, // amountETHMin,
        address, // to,
        uint256, // deadline,
        bool, // approveMax,
        uint8, // v,
        bytes32, // r,
        bytes32 // s
    ) external pure override returns (uint256) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, as FeeOnTransfer tokens are not supported by Gearbox
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256, // amountIn,
        uint256, // amountOutMin,
        address[] calldata, // path,
        address, // to,
        uint256 // deadline
    ) external pure override {
        revert NotImplementedException();
    }

    /// @dev Not implemented, as FeeOnTransfer tokens are not supported by Gearbox
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256, // amountOutMin,
        address[] calldata, // path,
        address, // to,
        uint256 // deadline
    ) external payable override {
        revert NotImplementedException();
    }

    /// @dev Not implemented, as FeeOnTransfer tokens are not supported by Gearbox
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256, // amountIn,
        uint256, // amountOutMin,
        address[] calldata, // path,
        address, // to,
        uint256 // deadline
    ) external pure override {
        revert NotImplementedException();
    }

    /// @dev Returns the address of the Uniswap pool factory
    function factory() external view override returns (address) {
        return IUniswapV2Router02(targetContract).factory();
    }

    /// @dev Returns the address of WETH
    function WETH() external view override returns (address) {
        return IUniswapV2Router02(targetContract).WETH();
    }

    /// @dev Not implemented, as Uniswap liquidity provision is not yet supported
    function addLiquidity(
        address, // tokenA,
        address, // tokenB,
        uint256, // amountADesired,
        uint256, // amountBDesired,
        uint256, // amountAMin,
        uint256, // amountBMin,
        address, // to,
        uint256 // deadline
    )
        external
        pure
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        revert NotImplementedException();
    }

    /// @dev Not implemented, as Uniswap liquidity provision is not yet supported
    function addLiquidityETH(
        address, // token,
        uint256, // amountTokenDesired,
        uint256, // amountTokenMin,
        uint256, // amountETHMin,
        address, // to,
        uint256 // deadline
    )
        external
        payable
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        revert NotImplementedException();
    }

    /// @dev Not implemented, as Uniswap liquidity provision is not yet supported
    function removeLiquidity(
        address, // tokenA,
        address, // tokenB,
        uint256, // liquidity,
        uint256, // amountAMin,
        uint256, // amountBMin,
        address, // to,
        uint256 // deadline
    ) external pure override returns (uint256, uint256) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, as Uniswap liquidity provision is not yet supported
    function removeLiquidityETH(
        address, // token,
        uint256, // liquidity,
        uint256, // amountTokenMin,
        uint256, // amountETHMin,
        address, // to,
        uint256 // deadline
    ) external pure override returns (uint256, uint256) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, as Uniswap liquidity provision is not yet supported
    function removeLiquidityWithPermit(
        address, // tokenA,
        address, // tokenB,
        uint256, // liquidity,
        uint256, // amountAMin,
        uint256, // amountBMin,
        address, // to,
        uint256, // deadline,
        bool, // approveMax,
        uint8, // v,
        bytes32, // r,
        bytes32 // s
    ) external pure override returns (uint256, uint256) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, as Uniswap liquidity provision is not yet supported
    function removeLiquidityETHWithPermit(
        address, // token,
        uint256, // liquidity,
        uint256, // amountTokenMin,
        uint256, // amountETHMin,
        address, // to,
        uint256, // deadline,
        bool, // approveMax,
        uint8, // v,
        bytes32, // r,
        bytes32 // s
    ) external pure override returns (uint256, uint256) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, as native ETH is not supported
    function swapExactETHForTokens(
        uint256, // amountOutMin,
        address[] calldata, // path,
        address, // to,
        uint256 // deadline
    ) external payable override returns (uint256[] memory) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, as native ETH is not supported
    function swapTokensForExactETH(
        uint256, // amountOut,
        uint256, // amountInMax,
        address[] calldata, // path,
        address, // to,
        uint256 // deadline
    ) external pure override returns (uint256[] memory) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, as native ETH is not supported
    function swapExactTokensForETH(
        uint256, // amountIn,
        uint256, //amountOutMin,
        address[] calldata, // path,
        address, // to,
        uint256 // deadline
    ) external pure override returns (uint256[] memory) {
        revert NotImplementedException();
    }

    /// @dev Not implemented, as native ETH is not supported
    function swapETHForExactTokens(
        uint256, // amountOut,
        address[] calldata, // path,
        address, // to,
        uint256 // deadline
    ) external payable override returns (uint256[] memory) {
        revert NotImplementedException();
    }

    /// @dev Returns the amount of token B that is equivalent
    /// to a specifed amount of token A, not accounting for fees
    /// @param amountA The amount of the input token being swapped
    /// @param reserveA Size of the input token reserve
    /// @param reserveB Size of the output token reserve
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external view override returns (uint256 amountB) {
        return
            IUniswapV2Router02(targetContract).quote(
                amountA,
                reserveA,
                reserveB
            ); // F:[AUV2-5]
    }

    /// @dev Returns the amount of the output token received when swapping
    /// a specific amount of the input token
    /// @param amountIn The amount of input token being swapped
    /// @param reserveIn Size of the input token reserve
    /// @param reserveOut Size of the output token reserve
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external view override returns (uint256 amountOut) {
        return
            IUniswapV2Router02(targetContract).getAmountOut(
                amountIn,
                reserveIn,
                reserveOut
            ); // F:[AUV2-6]
    }

    /// @dev Returns the amount of the input token required to
    /// receive a specified amount of the output token
    /// @param amountOut The desired amount of output token
    /// @param reserveIn Size of the input token reserve
    /// @param reserveOut Size of the output token reserve
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external view override returns (uint256 amountIn) {
        return
            IUniswapV2Router02(targetContract).getAmountIn(
                amountOut,
                reserveIn,
                reserveOut
            ); // F:[AUV2-7]
    }

    /// @dev Returns the amount of tokens received for each token along the path
    /// receive a specified amount of the output token
    /// @param amountIn The amount of input token being swapped
    /// @param path An array of token addresses
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        override
        returns (uint256[] memory amounts)
    {
        return IUniswapV2Router02(targetContract).getAmountsOut(amountIn, path); // F:[AUV2-8]
    }

    /// @dev Returns the amount of tokens required for each token in the path,
    /// in order to receive the spcified amount
    /// receive a specified amount of the output token
    /// @param amountOut The desired amount of output token
    /// @param path An array of token addresses
    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        override
        returns (uint256[] memory amounts)
    {
        return IUniswapV2Router02(targetContract).getAmountsIn(amountOut, path); // F:[AUV2-9]
    }

    /// @dev Performs sanity checks on a Uniswap V2 path and returns the input and output tokens
    /// @param path Path to check
    /// @notice Sanity checks include path length not being more than 4 (more than 3 hops) and intermediary tokens
    ///         being allowed as connectors
    function _parseUniV2Path(address[] memory path)
        internal
        view
        returns (
            bool valid,
            address tokenIn,
            address tokenOut
        )
    {
        valid = true;
        tokenIn = path[0];
        tokenOut = path[path.length - 1];

        uint256 len = path.length;

        if (len > 4) {
            valid = false;
        }

        for (uint256 i = 1; i < len - 1; ) {
            if (!isConnector(path[i])) {
                valid = false;
            }

            unchecked {
                ++i;
            }
        }
    }
}