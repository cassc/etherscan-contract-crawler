// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

import '../interfaces/IWETH.sol';
import '../interfaces/IUniswapV2Factory.sol';
import '../interfaces/IHelioswapFactory.sol';
import '../interfaces/ISwapRouter.sol';
import './interfaces/IKyberDMMFactory.sol';
import '../interfaces/IBalancerV2Vault.sol';
import '../base/Multicall.sol';
import '../libraries/TOKordinatorLibrary.sol';
import '../libraries/TransferHelper.sol';

import "hardhat/console.sol";

// TOKordinator
/// @title TokenStand Coordinator - Fantastic coordinator for swapping
/// @author Anh Dao Tuan <[email protected]>

// DEXes supported on ETH:
//      1. Uniswap V2
//      2. Sushiswap
//      3. Helioswap
//      4. Uniswap V3
//      5. Cryto Defi
//      5. Balancer
//      6. Kyber DMM

contract TOKordinatorV2ETH is Ownable, ReentrancyGuard, Multicall {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using UniswapV2Library for IUniswapV2Pair;
    using HelioswapLibrary for IHelioswap;
    using KyberDMMLibrary for IKyberDMMPool;
    // using BytesLib for bytes;
    using TOKordinatorLibrary for address;

    IWETH internal weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    // IWETH(0xc778417E063141139Fce010982780140Aa0cD5Ab);

    IERC20 internal usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    // IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    IUniswapV2Factory internal uniswapV2 = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    // IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV2Factory internal sushiswap = IUniswapV2Factory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);
    // IUniswapV2Factory(0xc35DADB65012eC5796536bD9864eD8773aBc74C4);
    IHelioswapFactory internal helioswap = IHelioswapFactory(0x9f07b190779d06e5f6CaCcAC251b240D8946741E);
    // IHeliowapFactory(0x9f07b190779d06e5f6CaCcAC251b240D8946741E);

    // UniswapV3
    ISwapRouter internal swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    // ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    IUniswapV2Factory internal croDefiSwap = IUniswapV2Factory(0x9DEB29c9a4c7A88a3C0257393b7f3335338D9A9D);
    // IUniswapV2Factory(0x9DEB29c9a4c7A88a3C0257393b7f3335338D9A9D);
    IKyberDMMFactory internal kyber = IKyberDMMFactory(0x833e4083B7ae46CeA85695c4f7ed25CDAd8886dE);
    // IKyberDMMFactory(0x833e4083B7ae46CeA85695c4f7ed25CDAd8886dE);
    IBalancerV2Vault internal balancer = IBalancerV2Vault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    // IBalancerV2Vault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);


    event SwappedOnTheOther(
        IERC20 indexed fromToken,
        IERC20 indexed destToken,
        uint256 fromTokenAmount,
        uint256 destTokenAmount,
        uint256 minReturn,
        uint256[] distribution
    );
    event SwappedOnUniswapV3(
        IERC20 indexed fromToken,
        IERC20 indexed toToken,
        uint256 fromTokenAmount,
        uint256 destTokenAmount,
        uint256 minReturn
    );
    event SwappedOnKyberDMM(
        IERC20 indexed fromToken,
        IERC20 indexed toToken,
        uint256 fromTokenAmount,
        uint256 destTokenAmount,
        uint256 minReturn
    );
    event SingleSwappedOnBalancerV2(
        IERC20 indexed fromToken,
        IERC20 indexed toToken,
        uint256 fromTokenAmount,
        uint256 destTokenAmount,
        uint256 minReturn
    );
    event BatchSwappedOnBalancerV2(
        IERC20 indexed fromToken,
        IERC20 indexed toToken,
        uint256 fromTokenAmount,
        uint256 destTokenAmount
    );

    // Number of DEX base on Uniswap V2
    uint256 internal constant DEXES_COUNT = 4;

    constructor(
    ) {
    }

    receive() external payable {}

    function swapOnTheOther(
        IERC20[][] calldata path,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution
    ) public payable nonReentrant returns (uint256 returnAmount) {
        function(IERC20[] calldata, uint256)[DEXES_COUNT] memory reserves = [
            _swapOnUniswapV2,
            _swapOnSushiswap,
            _swapOnHelioswap,
            _swapOnCroDefiSwap
        ];

        require(
            distribution.length <= reserves.length,
            'TOKordinator: distribution array should not exceed reserves array size.'
        );

        uint256 parts = 0;
        uint256 lastNonZeroIndex = 0;
        for (uint256 i = 0; i < distribution.length; i++) {
            if (distribution[i] > 0) {
                parts = parts.add(distribution[i]);
                lastNonZeroIndex = i;
            }
        }

        IERC20 fromToken = IERC20(path[lastNonZeroIndex][0]);
        IERC20 destToken = IERC20(path[lastNonZeroIndex][path[lastNonZeroIndex].length - 1]);

        if (parts == 0) {
            if (address(fromToken) == address(0)) {
                (bool success, ) = msg.sender.call{value: msg.value}('');
                require(success, 'TOKordinator: transfer failed');
                return msg.value;
            }
            return amount;
        }

        if (address(fromToken) != address(0)) {
            TransferHelper.safeTransferFrom(address(fromToken), msg.sender, address(this), amount);
        }

        uint256 remainingAmount = address(fromToken) == address(0)
            ? address(this).balance
            : fromToken.balanceOf(address(this));

        for (uint256 i = 0; i < distribution.length; i++) {
            if (distribution[i] == 0) {
                continue;
            }

            uint256 swapAmount = amount.mul(distribution[i]).div(parts);
            if (i == lastNonZeroIndex) {
                swapAmount = remainingAmount;
            }
            remainingAmount -= swapAmount;
            reserves[i](path[i], swapAmount);
        }

        returnAmount = address(destToken) == address(0) ? address(this).balance : destToken.balanceOf(address(this));
        require(returnAmount >= minReturn, 'TOKordinator: return amount was not enough');

        if (address(destToken) == address(0)) {
            (bool success, ) = msg.sender.call{value: returnAmount}('');
            require(success, 'TOKordinator: transfer failed');
        } else {
            TransferHelper.safeTransfer(address(destToken), msg.sender, returnAmount);
        }

        // uint256 remainingFromToken = address(fromToken) == address(0)
        //     ? address(this).balance
        //     : fromToken.balanceOf(address(this));
        // if (remainingFromToken > 0) {
        //     if (address(fromToken) == address(0)) {
        //         (bool success, ) = msg.sender.call{value: remainingFromToken}('');
        //         require(success, 'TOKordinator: transfer failed');
        //     } else {
        //         TransferHelper.safeTransfer(address(fromToken), msg.sender, remainingFromToken);
        //     }
        // }

        emit SwappedOnTheOther(fromToken, destToken, amount, returnAmount, minReturn, distribution);
    }

    function getUniswapV2AmountsOut(uint256 amountIn, IERC20[] memory path) public view returns (uint256[] memory) {
        IERC20[] memory realPath = formatPath(path);
        return UniswapV2Library.getAmountsOut(uniswapV2, amountIn, realPath);
    }

    function getSushiswapAmountsOut(uint256 amountIn, IERC20[] memory path) public view returns (uint256[] memory) {
        IERC20[] memory realPath = formatPath(path);
        return UniswapV2Library.getAmountsOut(sushiswap, amountIn, realPath);
    }

    function getHelioswapAmountsOut(uint256 amountIn, IERC20[] memory path) public view returns (uint256[] memory) {
        return HelioswapLibrary.getReturns(helioswap, amountIn, path);
    }

    function getCroDefiSwapAmountsOut(uint256 amountIn, IERC20[] memory path) public view returns (uint256[] memory) {
        IERC20[] memory realPath = formatPath(path);
        return UniswapV2Library.getAmountsOut(croDefiSwap, amountIn, realPath);
    }

    function getKyberDMMAmountsOut(
        uint256 amountIn,
        IERC20[] memory path,
        address[] memory poolsPath
    ) public view returns (uint256[] memory) {
        IERC20[] memory realPath = formatPath(path);
        return KyberDMMLibrary.getAmountsOut(amountIn, poolsPath, realPath);
    }

    function formatPath(IERC20[] memory path) public view returns (IERC20[] memory realPath) {
        realPath = new IERC20[](path.length);

        for (uint256 i; i < path.length; i++) {
            if (address(path[i]) == address(0)) {
                realPath[i] = weth;
                continue;
            }
            realPath[i] = path[i];
        }
    }

    function _swapOnUniswapV2(IERC20[] calldata path, uint256 amount) internal {
        IERC20[] memory realPath = formatPath(path);

        IUniswapV2Pair pair = uniswapV2.getPair(realPath[0], realPath[1]);
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(uniswapV2, amount, realPath);

        if (address(path[0]) == address(0)) {
            weth.deposit{value: amounts[0]}();
            assert(weth.transfer(address(pair), amounts[0]));
        } else {
            TransferHelper.safeTransfer(address(path[0]), address(pair), amounts[0]);
        }

        for (uint256 i; i < realPath.length - 1; i++) {
            (address input, address output) = (address(realPath[i]), address(realPath[i + 1]));
            (address token0, ) = TOKordinatorLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < realPath.length - 2
                ? address(uniswapV2.getPair(IERC20(output), realPath[i + 2]))
                : address(this);
            uniswapV2.getPair(IERC20(input), IERC20(output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }

        if (address(path[path.length - 1]) == address(0)) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOnSushiswap(IERC20[] calldata path, uint256 amount) internal {
        IERC20[] memory realPath = formatPath(path);

        IUniswapV2Pair pair = sushiswap.getPair(realPath[0], realPath[1]);
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(sushiswap, amount, realPath);

        if (address(path[0]) == address(0)) {
            weth.deposit{value: amounts[0]}();
            assert(weth.transfer(address(pair), amounts[0]));
        } else {
            TransferHelper.safeTransfer(address(path[0]), address(pair), amounts[0]);
        }

        for (uint256 i; i < realPath.length - 1; i++) {
            (address input, address output) = (address(realPath[i]), address(realPath[i + 1]));
            (address token0, ) = TOKordinatorLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < realPath.length - 2
                ? address(sushiswap.getPair(IERC20(output), realPath[i + 2]))
                : address(this);
            sushiswap.getPair(IERC20(input), IERC20(output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }

        if (address(path[path.length - 1]) == address(0)) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOnHelioswapInternal(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal {
        (IHelioswap pool, , , , , ) = helioswap.pools(fromToken, destToken);

        uint256 returnAmount = pool.getReturn(fromToken, destToken, amount);

        if (address(fromToken) != address(0)) {
            if (fromToken == usdt) {
                TransferHelper.safeApprove(address(fromToken), address(pool), 0);
            }
            TransferHelper.safeApprove(address(fromToken), address(pool), amount);
            pool.swap(fromToken, destToken, amount, returnAmount);
        } else {
            pool.swap{value: amount}(fromToken, destToken, amount, returnAmount);
        }
    }

    function _swapOnHelioswap(IERC20[] calldata path, uint256 amount) internal {
        uint256[] memory amounts = HelioswapLibrary.getReturns(helioswap, amount, path);

        for (uint256 i; i < path.length - 1; i++) {
            _swapOnHelioswapInternal(path[i], path[i + 1], amounts[i]);
        }
    }

    function swapOnUniswapV3(
        IERC20 tokenIn,
        IERC20 tokenOut,
        bytes memory path,
        uint256 deadline,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) public payable nonReentrant returns (uint256 returnAmount) {
        if (address(tokenIn) == address(0)) {
            require(msg.value >= amountIn, 'TOKordinator: value does not enough');
        }

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams(
            path,
            address(this),
            deadline,
            amountIn,
            amountOutMinimum
        );

        if (address(tokenIn) == address(0)) {
            returnAmount = swapRouter.exactInput{value: amountIn}(params);
            swapRouter.refundETH();
        } else {
            TransferHelper.safeTransferFrom(address(tokenIn), msg.sender, address(this), amountIn);
            if (tokenIn == usdt) {
                TransferHelper.safeApprove(address(tokenIn), address(swapRouter), 0);
            }
            TransferHelper.safeApprove(address(tokenIn), address(swapRouter), amountIn);

            returnAmount = swapRouter.exactInput(params);
        }

        if (address(tokenOut) == address(0)) {
            weth.withdraw(returnAmount);
            (bool success, ) = msg.sender.call{value: returnAmount}('');
            require(success, 'TOKordinator: transfer failed');
        } else {
            TransferHelper.safeTransfer(address(tokenOut), msg.sender, returnAmount);
        }

        emit SwappedOnUniswapV3(tokenIn, tokenOut, amountIn, returnAmount, amountOutMinimum);
    }

    function _swapOnCroDefiSwap(IERC20[] calldata path, uint256 amount) internal {
        IERC20[] memory realPath = formatPath(path);

        IUniswapV2Pair pair = croDefiSwap.getPair(realPath[0], realPath[1]);
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(croDefiSwap, amount, realPath);

        if (address(path[0]) == address(0)) {
            weth.deposit{value: amounts[0]}();
            assert(weth.transfer(address(pair), amounts[0]));
        } else {
            TransferHelper.safeTransfer(address(path[0]), address(pair), amounts[0]);
        }

        for (uint256 i; i < realPath.length - 1; i++) {
            (address input, address output) = (address(realPath[i]), address(realPath[i + 1]));
            (address token0, ) = TOKordinatorLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < realPath.length - 2
                ? address(croDefiSwap.getPair(IERC20(output), realPath[i + 2]))
                : address(this);
            croDefiSwap.getPair(IERC20(input), IERC20(output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }

        if (address(path[path.length - 1]) == address(0)) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function swapOnKyberDMM(
        IERC20[] calldata path,
        address[] calldata poolsPath,
        uint256 amount,
        uint256 minReturn
    ) public payable nonReentrant returns (uint256 returnAmount) {
        if (address(path[0]) == address(0)) {
            require(msg.value >= amount, 'TOKordinator: value does not enough');
        }

        IERC20 destToken = IERC20(path[path.length - 1]);
        IERC20[] memory realPath = formatPath(path);

        uint256[] memory amounts = KyberDMMLibrary.getAmountsOut(amount, poolsPath, realPath);

        if (address(path[0]) == address(0)) {
            weth.deposit{value: amounts[0]}();
            assert(weth.transfer(poolsPath[0], amounts[0]));
        } else {
            TransferHelper.safeTransferFrom(address(path[0]), msg.sender, poolsPath[0], amounts[0]);
        }

        for (uint256 i; i < realPath.length - 1; i++) {
            (address input, address output) = (address(realPath[i]), address(realPath[i + 1]));
            (address token0, ) = TOKordinatorLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < realPath.length - 2 ? poolsPath[i + 1] : address(this);
            IKyberDMMPool(poolsPath[i]).swap(amount0Out, amount1Out, to, new bytes(0));
        }

        returnAmount = address(destToken) == address(0) ? weth.balanceOf(address(this)) : destToken.balanceOf(address(this));
        require(returnAmount >= minReturn, 'TOKordinator: return amount was not enough');

        if (address(destToken) == address(0)) {
            weth.withdraw(returnAmount);
            (bool success, ) = msg.sender.call{value: returnAmount}('');
            require(success, 'TOKordinator: transfer failed');
        } else {
            TransferHelper.safeTransfer(address(destToken), msg.sender, returnAmount);
        }

        // uint256 remainingFromToken = address(path[0]) == address(0)
        //     ? address(this).balance
        //     : path[0].balanceOf(address(this));
        // if (remainingFromToken > 0) {
        //     if (address(path[0]) == address(0)) {
        //         (bool success, ) = msg.sender.call{value: remainingFromToken}('');
        //         require(success, 'TOKordinator: transfer failed');
        //     } else {
        //         TransferHelper.safeTransfer(address(path[0]), msg.sender, remainingFromToken);
        //     }
        // }

        emit SwappedOnKyberDMM(path[0], destToken, amount, returnAmount, minReturn);
    }

    function singleSwapOnBalancerV2(
        bytes32 poolId,
        IAsset assetIn,
        IAsset assetOut,
        uint256 amountIn,
        uint256 amountOutMinimum,
        uint256 deadline
    ) public payable nonReentrant returns (uint256 returnAmount) {
        if (address(assetIn) == address(0)) {
            require(msg.value >= amountIn, 'TOKordinator: value does not enough');
        }

        IBalancerV2Vault.SingleSwap memory singleSwap = IBalancerV2Vault.SingleSwap(
            poolId,
            IBalancerV2Vault.SwapKind.GIVEN_IN,
            assetIn,
            assetOut,
            amountIn,
            '0x'
        );

        IBalancerV2Vault.FundManagement memory funds = IBalancerV2Vault.FundManagement(
            address(this),
            false,
            address(this),
            false
        );

        if (address(assetIn) == address(0)) {
            returnAmount = balancer.swap{value: amountIn}(
                singleSwap,
                funds,
                amountOutMinimum,
                deadline
            );
        } else {
            TransferHelper.safeTransferFrom(address(singleSwap.assetIn), msg.sender, address(this), amountIn);
            if (address(assetIn) == address(usdt)) {
                TransferHelper.safeApprove(address(assetIn), address(balancer), 0);
            }
            TransferHelper.safeApprove(address(assetIn), address(balancer), amountIn);
            returnAmount = balancer.swap(
                singleSwap,
                funds,
                amountOutMinimum,
                deadline
            );
        }

        require(returnAmount >= amountOutMinimum, "TOKordinator: return amount was not enough");
        if (address(assetOut) == address(0)) {
            (bool success, ) = msg.sender.call{value: returnAmount}('');
            require(success, 'TOKordinator: transfer failed');
        } else {
            TransferHelper.safeTransfer(address(assetOut), msg.sender, returnAmount);
        }

        emit SingleSwappedOnBalancerV2(IERC20(address(assetIn)), IERC20(address(assetOut)), amountIn, returnAmount, amountOutMinimum);
    }

    function batchSwapOnBalancerV2(
        IERC20 tokenIn,
        IERC20 tokenOut,
        IBalancerV2Vault.BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        int256[] memory limits,
        uint256 amountOutMinimum,
        uint256 deadline
    ) public payable nonReentrant returns (uint256 returnAmount) {
        uint256 amountIn = swaps[0].amount;
        int256[] memory returnAmounts;
        if (address(tokenIn) == address(0)) {
            require(msg.value >= amountIn, 'TOKordinator: value does not enough');
        }

        IBalancerV2Vault.FundManagement memory funds = IBalancerV2Vault.FundManagement(
            address(this),
            false,
            address(this),
            false
        );

        if (address(tokenIn) == address(0)) {
            returnAmounts = balancer.batchSwap{value: amountIn}(
                IBalancerV2Vault.SwapKind.GIVEN_IN,
                swaps,
                assets,
                funds,
                limits,
                deadline
            );
        } else {
            TransferHelper.safeTransferFrom(address(tokenIn), msg.sender, address(this), amountIn);
            if (address(tokenIn) == address(usdt)) {
                TransferHelper.safeApprove(address(tokenIn), address(balancer), 0);
            }
            TransferHelper.safeApprove(address(tokenIn), address(balancer), amountIn);

            returnAmounts = balancer.batchSwap(
                IBalancerV2Vault.SwapKind.GIVEN_IN,
                swaps,
                assets,
                funds,
                limits,
                deadline
            );
        }

        if (returnAmounts[returnAmounts.length - 1] < 0) {
          returnAmount = uint256(returnAmounts[returnAmounts.length - 1] * -1);
        } else {
          returnAmount = uint256(returnAmounts[returnAmounts.length - 1]);
        }

        require(returnAmount >= amountOutMinimum, "TOKordinator: return amount was not enough");
        if (address(tokenOut) == address(0)) {
            (bool success, ) = msg.sender.call{value: returnAmount}('');
            require(success, 'TOKordinator: transfer failed');
        } else {
            TransferHelper.safeTransfer(address(tokenOut), msg.sender, returnAmount);
        }

        emit BatchSwappedOnBalancerV2(tokenIn, tokenOut, amountIn, returnAmount);
    }

    // emergency case
    function rescueFund(IERC20 token) public onlyOwner {
        if (address(token) == address(0)) {
            (bool success, ) = msg.sender.call{value: address(this).balance}('');
            require(success, 'TOKordinator: fail to rescue Ether');
        } else {
            TransferHelper.safeTransfer(address(token), msg.sender, token.balanceOf(address(this)));
        }
    }
}