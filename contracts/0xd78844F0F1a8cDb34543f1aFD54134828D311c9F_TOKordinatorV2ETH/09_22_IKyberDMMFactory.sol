// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import './IKyberDMMPool.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '../../libraries/TOKordinatorLibrary.sol';

interface IKyberDMMFactory {
    function isPool(
        IERC20 token0,
        IERC20 token1,
        IERC20 pool
    ) external view returns (bool);
}

library KyberDMMLibrary {
    using SafeMath for uint256;

    uint256 private constant PRECISION = 1e18;

    /// @dev fetch the reserves and fee for a pool, used for trading purposes
    function getTradeInfo(
        address pool,
        IERC20 tokenA,
        IERC20 tokenB
    )
        internal
        view
        returns (
            uint256 reserveA,
            uint256 reserveB,
            uint256 vReserveA,
            uint256 vReserveB,
            uint256 feeInPrecision
        )
    {
        (address token0, ) = TOKordinatorLibrary.sortTokens(address(tokenA), address(tokenB));
        uint256 reserve0;
        uint256 reserve1;
        uint256 vReserve0;
        uint256 vReserve1;
        (reserve0, reserve1, vReserve0, vReserve1, feeInPrecision) = IKyberDMMPool(pool).getTradeInfo();
        (reserveA, reserveB, vReserveA, vReserveB) = address(tokenA) == token0
            ? (reserve0, reserve1, vReserve0, vReserve1)
            : (reserve1, reserve0, vReserve1, vReserve0);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 vReserveIn,
        uint256 vReserveOut,
        uint256 feeInPrecision
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "TOKordinator: insufficient input amount");
        require(reserveIn > 0 && reserveOut > 0, "TOKordinator: insufficient liquidity");
        uint256 amountInWithFee = amountIn.mul(PRECISION.sub(feeInPrecision)).div(PRECISION);
        uint256 numerator = amountInWithFee.mul(vReserveOut);
        uint256 denominator = vReserveIn.add(amountInWithFee);
        amountOut = numerator.div(denominator);
        require(reserveOut > amountOut, "TOKordinator: insufficient liquidity");
    }

    function getAmountsOut(
        uint256 amountIn,
        address[] memory poolsPath,
        IERC20[] memory path
    ) internal view returns (uint256[] memory amounts) {
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (
                uint256 reserveIn,
                uint256 reserveOut,
                uint256 vReserveIn,
                uint256 vReserveOut,
                uint256 feeInPrecision
            ) = getTradeInfo(poolsPath[i], path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, vReserveIn, vReserveOut, feeInPrecision);
        }
    }

    function verifyPoolsPathSwap(
        IKyberDMMFactory kyber,
        IERC20[] memory poolsPath,
        IERC20[] memory path
    ) internal view {
        require(path.length >= 2, 'TOKordinator: invalid path');
        require(poolsPath.length == path.length - 1, 'TOKordinator: invalid Kyber pools path');
        for (uint256 i = 0; i < poolsPath.length; i++) {
            kyber.isPool(path[i], path[i + 1], poolsPath[i]);
        }
    }
}