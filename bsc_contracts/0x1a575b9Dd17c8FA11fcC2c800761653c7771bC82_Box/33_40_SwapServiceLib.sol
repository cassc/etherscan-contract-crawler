// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Math.sol";

import "./InvestableLib.sol";
import "../../dependencies/swap/IUniswapV2LikeRouter.sol";
import "../../dependencies/traderjoe/ITraderJoeLBRouter.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

error InvalidSwapServiceProvider();

enum SwapServiceProvider {
    AvalancheTraderJoe,
    AvalancheTraderJoeV2,
    AvalanchePangolin,
    BscPancakeSwap
}

struct SwapService {
    SwapServiceProvider provider;
    address router;
}

library SwapServiceLib {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function swapExactTokensForTokens(
        SwapService memory swapService,
        uint256 amountIn,
        uint256 minAmountOut,
        address[] memory path,
        uint256[] memory binSteps
    ) internal returns (uint256 amountOut) {
        if (
            swapService.provider == SwapServiceProvider.AvalancheTraderJoe ||
            swapService.provider == SwapServiceProvider.AvalanchePangolin ||
            swapService.provider == SwapServiceProvider.BscPancakeSwap
        ) {
            IUniswapV2LikeRouter uniswapV2LikeRouter = IUniswapV2LikeRouter(
                swapService.router
            );

            IERC20Upgradeable(path[0]).approve(
                address(uniswapV2LikeRouter),
                amountIn
            );

            amountOut = uniswapV2LikeRouter.swapExactTokensForTokens(
                amountIn,
                minAmountOut,
                path,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            )[path.length - 1];
        } else if (
            swapService.provider == SwapServiceProvider.AvalancheTraderJoeV2
        ) {
            ITraderJoeLBRouter traderjoeLBRouter = ITraderJoeLBRouter(
                swapService.router
            );

            IERC20Upgradeable(path[0]).approve(
                address(traderjoeLBRouter),
                amountIn
            );

            amountOut = traderjoeLBRouter.swapExactTokensForTokens(
                amountIn,
                minAmountOut,
                binSteps,
                path,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            );
        } else {
            revert InvalidSwapServiceProvider();
        }
    }

    function swapTokensForExactTokens(
        SwapService memory swapService,
        uint256 amountOut,
        uint256 maxAmountIn,
        address[] memory path,
        uint256[] memory binSteps
    ) internal returns (uint256 amountIn) {
        if (
            swapService.provider == SwapServiceProvider.AvalancheTraderJoe ||
            swapService.provider == SwapServiceProvider.AvalanchePangolin ||
            swapService.provider == SwapServiceProvider.BscPancakeSwap
        ) {
            IUniswapV2LikeRouter uniswapV2LikeRouter = IUniswapV2LikeRouter(
                swapService.router
            );

            uint256[] memory maxAmountInCalculated = uniswapV2LikeRouter
                .getAmountsIn(amountOut, path);

            uint256 maxAmountInFinal = Math.min(
                maxAmountInCalculated[0],
                maxAmountIn
            );
            IERC20Upgradeable(path[0]).approve(
                address(uniswapV2LikeRouter),
                Math.min(maxAmountInCalculated[0], maxAmountIn)
            );

            amountIn = uniswapV2LikeRouter.swapTokensForExactTokens(
                amountOut,
                maxAmountInFinal,
                path,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            )[0];
        } else if (
            swapService.provider == SwapServiceProvider.AvalancheTraderJoeV2
        ) {
            ITraderJoeLBRouter traderjoeLBRouter = ITraderJoeLBRouter(
                swapService.router
            );

            IERC20Upgradeable(path[0]).approve(
                address(traderjoeLBRouter),
                maxAmountIn
            );

            amountIn = traderjoeLBRouter.swapTokensForExactTokens(
                amountOut,
                maxAmountIn,
                binSteps,
                path,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            )[0];

            IERC20Upgradeable(path[0]).approve(address(traderjoeLBRouter), 0);
        } else {
            revert InvalidSwapServiceProvider();
        }
    }

    function swapExactTokensForNative(
        SwapService memory swapService,
        uint256 amountIn,
        uint256 minAmountOut,
        address[] memory path
    ) internal returns (uint256 amountOut) {
        uint256 pathOldLength = path.length;
        address[] memory pathNew = new address[](pathOldLength + 1);
        for (uint256 i = 0; i < pathOldLength; ++i) {
            pathNew[i] = path[i];
        }
        if (swapService.provider == SwapServiceProvider.BscPancakeSwap) {
            pathNew[pathOldLength] = address(InvestableLib.BINANCE_WBNB);
            IUniswapV2LikeRouter router = IUniswapV2LikeRouter(
                swapService.router
            );

            IERC20Upgradeable(pathNew[0]).approve(address(router), amountIn);

            amountOut = router.swapExactTokensForETH(
                amountIn,
                minAmountOut,
                pathNew,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            )[pathOldLength];
        } else {
            revert InvalidSwapServiceProvider();
        }
    }

    function swapExactNativeForTokens(
        SwapService memory swapService,
        uint256 amountIn,
        uint256 minAmountOut,
        address[] memory path
    ) internal returns (uint256 amountOut) {
        uint256 pathOldLength = path.length;
        address[] memory pathNew = new address[](pathOldLength + 1);
        for (uint256 i = 1; i <= pathOldLength; ++i) {
            pathNew[i] = path[i - 1];
        }

        if (swapService.provider == SwapServiceProvider.BscPancakeSwap) {
            pathNew[0] = address(InvestableLib.BINANCE_WBNB);
            IUniswapV2LikeRouter router = IUniswapV2LikeRouter(
                swapService.router
            );

            amountOut = router.swapExactETHForTokens{ value: amountIn }(
                minAmountOut,
                pathNew,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            )[pathOldLength];
        } else {
            revert InvalidSwapServiceProvider();
        }
    }

    function swapTokensForExactNative(
        SwapService memory swapService,
        uint256 amountOut,
        uint256 maxAmountIn,
        address[] memory path
    ) internal returns (uint256 amountIn) {
        uint256 pathOldLength = path.length;
        address[] memory pathNew = new address[](pathOldLength + 1);
        for (uint256 i = 0; i < pathOldLength; ++i) {
            pathNew[i] = path[i];
        }

        if (swapService.provider == SwapServiceProvider.BscPancakeSwap) {
            pathNew[pathOldLength] = address(InvestableLib.BINANCE_WBNB);
            IUniswapV2LikeRouter router = IUniswapV2LikeRouter(
                swapService.router
            );

            uint256[] memory maxAmountInCalculated = router.getAmountsIn(
                amountOut,
                pathNew
            );

            uint256 maxAmountInFinal = Math.min(
                maxAmountInCalculated[0],
                maxAmountIn
            );
            IERC20Upgradeable(pathNew[0]).approve(
                address(router),
                maxAmountInFinal
            );

            amountIn = router.swapTokensForExactETH(
                amountOut,
                maxAmountInFinal,
                pathNew,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            )[0];
        } else {
            revert InvalidSwapServiceProvider();
        }
    }

    function getAmountsIn(
        SwapService memory swapService,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        if (
            swapService.provider == SwapServiceProvider.AvalancheTraderJoe ||
            swapService.provider == SwapServiceProvider.AvalanchePangolin ||
            swapService.provider == SwapServiceProvider.BscPancakeSwap
        ) {
            IUniswapV2LikeRouter uniswapV2LikeRouter = IUniswapV2LikeRouter(
                swapService.router
            );

            amounts = uniswapV2LikeRouter.getAmountsIn(amountOut, path);
        } else {
            revert InvalidSwapServiceProvider();
        }
    }

    function getAmountsOut(
        SwapService memory swapService,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        if (
            swapService.provider == SwapServiceProvider.AvalancheTraderJoe ||
            swapService.provider == SwapServiceProvider.AvalanchePangolin ||
            swapService.provider == SwapServiceProvider.BscPancakeSwap
        ) {
            IUniswapV2LikeRouter uniswapV2LikeRouter = IUniswapV2LikeRouter(
                swapService.router
            );

            amounts = uniswapV2LikeRouter.getAmountsOut(amountIn, path);
        } else {
            revert InvalidSwapServiceProvider();
        }
    }
}