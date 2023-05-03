// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

/*
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         

 * App:             https://apeswap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Discord:         https://discord.com/invite/apeswap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "./lib/IApeSwapZap.sol";
import "./lib/IApeRouter02.sol";
import "./lib/IApeFactory.sol";
import "./lib/IApePair.sol";
import "./utils/TransferHelper.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ApeSwapZap is TransferHelper, IApeSwapZap, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct BalanceLocalVars {
        uint256 amount0;
        uint256 amount1;
    }

    IApeRouter02 public immutable router;
    IApeFactory public immutable factory;

    event Zap(address inputToken, uint256 inputAmount, address[] lpTokens, uint256 amountA, uint256 amountB);

    constructor(IApeRouter02 _router) TransferHelper(IWETH(_router.WETH())) {
        router = _router;
        factory = IApeFactory(router.factory());
    }

    /// @dev The receive method is used as a fallback function in a contract
    /// and is called when ether is sent to a contract with no calldata.
    receive() external payable {
        require(msg.sender == address(WNATIVE), "ApeSwapZap: Only receive ether from wrapped");
    }

    /// @notice Zap single token to LP
    /// @param inputToken Input token
    /// @param inputAmount Input amount
    /// @param lpTokens Tokens of LP to zap to
    /// @param path0 Path from input token to LP token0
    /// @param path1 Path from input token to LP token1
    /// @param minAmountsSwap The minimum amount of output tokens that must be received for swap
    /// @param minAmountsLP AmountAMin and amountBMin for adding liquidity
    /// @param to address to receive LPs
    /// @param deadline Unix timestamp after which the transaction will revert
    function zap(
        IERC20 inputToken,
        uint256 inputAmount,
        address[] memory lpTokens, //[tokenA, tokenB]
        address[] calldata path0,
        address[] calldata path1,
        uint256[] memory minAmountsSwap, //[A, B]
        uint256[] memory minAmountsLP, //[amountAMin, amountBMin]
        address to,
        uint256 deadline
    ) external override nonReentrant {
        inputAmount = _transferIn(inputToken, inputAmount);
        _zap(
            ZapParams({
                inputToken: inputToken,
                inputAmount: inputAmount,
                lpTokens: lpTokens,
                path0: path0,
                path1: path1,
                minAmountsSwap: minAmountsSwap,
                minAmountsLP: minAmountsLP,
                to: to,
                deadline: deadline
            }),
            false
        );
    }

    /// @notice Zap native token to LP
    /// @param lpTokens Tokens of LP to zap to
    /// @param path0 Path from input token to LP token0
    /// @param path1 Path from input token to LP token1
    /// @param minAmountsSwap The minimum amount of output tokens that must be received for swap
    /// @param minAmountsLP AmountAMin and amountBMin for adding liquidity
    /// @param to address to receive LPs
    /// @param deadline Unix timestamp after which the transaction will revert
    function zapNative(
        address[] memory lpTokens, //[tokenA, tokenB]
        address[] calldata path0,
        address[] calldata path1,
        uint256[] memory minAmountsSwap, //[A, B]
        uint256[] memory minAmountsLP, //[amountAMin, amountBMin]
        address to,
        uint256 deadline
    ) external payable override nonReentrant {
        (IERC20 weth, uint256 inputAmount) = _wrapNative();
        _zap(
            ZapParams({
                inputToken: weth,
                inputAmount: inputAmount,
                lpTokens: lpTokens,
                path0: path0,
                path1: path1,
                minAmountsSwap: minAmountsSwap,
                minAmountsLP: minAmountsLP,
                to: to,
                deadline: deadline
            }),
            true
        );
    }

    /// @notice get min amounts for swaps
    /// @param inputAmount total input amount for swap
    /// @param path0 path from input token to LP token0
    /// @param path1 path from input token to LP token1
    function getMinAmounts(
        uint256 inputAmount,
        address[] calldata path0,
        address[] calldata path1
    ) external view override returns (uint256[2] memory minAmountsSwap, uint256[2] memory minAmountsLP) {
        require(path0.length >= 2 || path1.length >= 2, "ApeSwapZap: Needs at least one path");

        uint256 inputAmountHalf = inputAmount / 2;

        uint256 minAmountSwap0 = inputAmountHalf;
        if (path0.length != 0) {
            uint256[] memory amountsOut0 = router.getAmountsOut(inputAmountHalf, path0);
            minAmountSwap0 = amountsOut0[amountsOut0.length - 1];
        }

        uint256 minAmountSwap1 = inputAmountHalf;
        if (path1.length != 0) {
            uint256[] memory amountsOut1 = router.getAmountsOut(inputAmountHalf, path1);
            minAmountSwap1 = amountsOut1[amountsOut1.length - 1];
        }

        address token0 = path0.length == 0 ? path1[0] : path0[path0.length - 1];
        address token1 = path1.length == 0 ? path0[0] : path1[path1.length - 1];

        IApePair lp = IApePair(factory.getPair(token0, token1));
        (uint256 reserveA, uint256 reserveB, ) = lp.getReserves();
        if (token0 == lp.token1()) {
            (reserveA, reserveB) = (reserveB, reserveA);
        }
        uint256 amountB = router.quote(minAmountSwap0, reserveA, reserveB);

        minAmountsSwap = [minAmountSwap0, minAmountSwap1];
        minAmountsLP = [minAmountSwap0, amountB];
    }

    /// @notice Swap single token to single token
    /// @param amountIn Amount of input token to pass in
    /// @param amountOutMin Min amount of output token to accept
    /// @param path Path from input token to output token
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @return amountOut The final amount of output tokens received
    function _routerSwap(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        uint256 deadline,
        bool needApproval
    ) internal returns (uint256 amountOut) {
        require(amountIn > 0, "ApeSwapZap: amountIn must be greater than zero");
        if (needApproval) {
            IERC20(path[0]).approve(address(router), amountIn);
        }
        address outputToken = path[path.length - 1];
        uint256 balanceBefore = _getBalance(IERC20(outputToken));
        router.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);
        amountOut = _getBalance(IERC20(outputToken)) - balanceBefore;
    }

    /// @dev Zap single token input to UniV2 LP token
    /// @param zapParams ZapParams struct
    /// @param nativeOut Whether to unwrap native token when refunding sender
    function _zap(ZapParams memory zapParams, bool nativeOut) internal {
        require(zapParams.inputAmount > 0, "ApeSwapZap: inputAmount must be greater than zero");
        require(zapParams.to != address(0), "ApeSwapZap: Can't zap to null address");
        require(zapParams.lpTokens.length == 2, "ApeSwapZap: need exactly 2 tokens to form a LP");
        require(
            factory.getPair(zapParams.lpTokens[0], zapParams.lpTokens[1]) != address(0),
            "ApeSwapZap: Pair doesn't exist"
        );

        BalanceLocalVars memory vars;

        zapParams.inputToken.approve(address(router), zapParams.inputAmount);

        vars.amount0 = zapParams.inputAmount / 2;
        if (zapParams.lpTokens[0] != address(zapParams.inputToken)) {
            uint256 path0Length = zapParams.path0.length;
            require(path0Length > 0, "ApeSwapZap: path0 is required for this operation");
            require(zapParams.path0[0] == address(zapParams.inputToken), "ApeSwapZap: wrong path path0[0]");
            require(zapParams.path0[path0Length - 1] == zapParams.lpTokens[0], "ApeSwapZap: wrong path path0[-1]");
            vars.amount0 = _routerSwap(
                vars.amount0,
                zapParams.minAmountsSwap[0],
                zapParams.path0,
                zapParams.deadline,
                false
            );
        }

        vars.amount1 = zapParams.inputAmount / 2;
        if (zapParams.lpTokens[1] != address(zapParams.inputToken)) {
            uint256 path1Length = zapParams.path1.length;
            require(path1Length > 0, "ApeSwapZap: path1 is required for this operation");
            require(zapParams.path1[0] == address(zapParams.inputToken), "ApeSwapZap: wrong path path1[0]");
            require(zapParams.path1[path1Length - 1] == zapParams.lpTokens[1], "ApeSwapZap: wrong path path1[-1]");
            vars.amount1 = _routerSwap(
                vars.amount1,
                zapParams.minAmountsSwap[1],
                zapParams.path1,
                zapParams.deadline,
                false
            );
        }

        IERC20(zapParams.lpTokens[0]).approve(address(router), vars.amount0);
        IERC20(zapParams.lpTokens[1]).approve(address(router), vars.amount1);
        (uint256 amountA, uint256 amountB, ) = router.addLiquidity(
            zapParams.lpTokens[0],
            zapParams.lpTokens[1],
            vars.amount0,
            vars.amount1,
            zapParams.minAmountsLP[0],
            zapParams.minAmountsLP[1],
            zapParams.to,
            zapParams.deadline
        );

        emit Zap(address(zapParams.inputToken), zapParams.inputAmount, zapParams.lpTokens, amountA, amountB);

        if (zapParams.lpTokens[0] == address(WNATIVE)) {
            // Ensure WNATIVE is called last
            _transferOut(IERC20(zapParams.lpTokens[1]), vars.amount1 - amountB, msg.sender, nativeOut);
            _transferOut(IERC20(zapParams.lpTokens[0]), vars.amount0 - amountA, msg.sender, nativeOut);
        } else {
            _transferOut(IERC20(zapParams.lpTokens[0]), vars.amount0 - amountA, msg.sender, nativeOut);
            _transferOut(IERC20(zapParams.lpTokens[1]), vars.amount1 - amountB, msg.sender, nativeOut);
        }
    }
}