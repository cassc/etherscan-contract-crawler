//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "../interfaces/IPlaygroundPair.sol";

library PlaygroundLibrary {
    uint256 private constant DIVIDER = 1000;
    uint256 private constant FEE_MULTIPLIER = 997;

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 totalFee,
        bool hasFees
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "KLib: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "KLib: INSUFFICIENT_LIQUIDITY"
        );
        uint256 feeOut = hasFees ? DIVIDER - totalFee : FEE_MULTIPLIER;
        uint256 numerator = reserveIn * amountOut * DIVIDER;
        uint256 denominator = (reserveOut - amountOut) * feeOut;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "KLib: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (bool hasFees, uint256 fee) = getBaseAndFee(
                factory,
                path[i - 1],
                path[i]
            );
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(
                amounts[i],
                reserveIn,
                reserveOut,
                fee,
                hasFees
            );
        }
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 totalFee,
        bool hasFees
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "KLib: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "KLib: INSUFFICIENT_LIQUIDITY"
        );
        uint256 feeIn = hasFees ? DIVIDER - totalFee : FEE_MULTIPLIER;
        uint256 amountInWithFee = amountIn * feeIn;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "KLib: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (bool hasFees, uint256 fee) = getBaseAndFee(
                factory,
                path[i],
                path[i + 1]
            );
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(
                amounts[i],
                reserveIn,
                reserveOut,
                fee,
                hasFees
            );
        }
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "KLib: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "KLib: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        bytes32 _data = keccak256(
            abi.encodePacked(
                hex"ff",
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex"9acfe9e4e9bb795c2f5f2d3759495bcb706d8be1108ae2f05d4e28cdf8d1da93" // init code hash
            )
        );

        pair = address(uint160(uint256(_data)));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        IPlaygroundPair pair = IPlaygroundPair(pairFor(factory, tokenA, tokenB));
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "KLib: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "KLib: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }

    // fetches and returns the total fee and base token
    function getBaseAndFee(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (bool hasFees, uint256 fee) {
        IPlaygroundPair pair = IPlaygroundPair(pairFor(factory, tokenA, tokenB));
        hasFees = pair.feeToken() != address(0);
        fee = pair.totalFee();

        return (hasFees, fee);
    }

    // given an input amount, return the a new amount with fees applied and the fee amount
    function applyFee(uint256 amount, uint256 fee)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 appliedFee = (amount * fee) / DIVIDER;
        amount = amount - appliedFee;

        return (amount, appliedFee);
    }
}