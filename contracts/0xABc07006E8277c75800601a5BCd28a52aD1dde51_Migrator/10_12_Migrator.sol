// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./core/interfaces/ISCRYFactory.sol";
import "./core/interfaces/ISCRYPair.sol";
import "./periphery/libraries/SCRYLibrary.sol";
import "./external/IUniswapV2PairBurn.sol";

// Helps you migrate your existing Uniswap LP tokens to SCRY LP Tokens
contract Migrator {
    using SafeERC20 for IERC20;

    ISCRYFactory public factory;

    constructor(ISCRYFactory _factory) public {
        factory = _factory;
    }

    function migrateWithPermit(
        address lpToken,
        uint256 liquidity,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        IUniswapV2PairBurn pair = IUniswapV2PairBurn(lpToken);
        pair.permit(msg.sender, address(this), liquidity, deadline, v, r, s);

        migrate(lpToken, liquidity, amount0Min, amount1Min, deadline);
    }

    // msg.sender should have approved 'liquidity' amount of LP token of 'tokenA' and 'tokenB'
    function migrate(
        address lpToken,
        uint256 liquidity,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 deadline
    ) public {
        require(deadline >= block.timestamp, 'Migrator: EXPIRED');

        // Remove liquidity from the old pair with permit
        (uint256 amount0, uint256 amount1) = removeLiquidity(
            lpToken,
            liquidity,
            amount0Min,
            amount1Min
        );

        IUniswapV2PairBurn pair = IUniswapV2PairBurn(lpToken);
        address token0 = pair.token0();
        address token1 = pair.token1();
        // Add liquidity to the new router
        (uint256 pooledAmount0, uint256 pooledAmount1) = addLiquidity(
            token0, token1, amount0, amount1, amount0Min, amount1Min);
        // Send remaining tokens to msg.sender
        if (amount0 > pooledAmount0) {
            IERC20(token0).safeTransfer(msg.sender, amount0 - pooledAmount0);
        }
        if (amount1 > pooledAmount1) {
            IERC20(token1).safeTransfer(msg.sender, amount1 - pooledAmount1);
        }
    }

    function removeLiquidity(
        address lpToken,
        uint256 liquidity,
        uint256 amount0Min,
        uint256 amount1Min
    ) internal returns (uint256 amount0, uint256 amount1) {
        IUniswapV2PairBurn pair = IUniswapV2PairBurn(lpToken);
        pair.transferFrom(msg.sender, address(pair), liquidity);
        (amount0, amount1) = pair.burn(address(this));
        require(amount0 >= amount0Min, 'Migrator: INSUFFICIENT_0_AMOUNT');
        require(amount1 >= amount1Min, 'Migrator: INSUFFICIENT_1_AMOUNT');
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint amountA, uint amountB) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = SCRYLibrary.pairFor(address(factory), tokenA, tokenB);
        IERC20(tokenA).safeTransfer(pair, amountA);
        IERC20(tokenB).safeTransfer(pair, amountB);
        ISCRYPair(pair).mint(msg.sender);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        if (factory.getPair(tokenA, tokenB) == address(0)) {
            factory.createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB,) = SCRYLibrary.getReservesAndFee(address(factory), tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = SCRYLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'Migrator: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
                require(amountA >= amountAMin, 'Migrator: INSUFFICIENT_A_AMOUNT');
            } else {
                uint256 amountAOptimal = SCRYLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'Migrator: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
                require(amountB >= amountBMin, 'Migrator: INSUFFICIENT_B_AMOUNT');
            }
        }
    }
}