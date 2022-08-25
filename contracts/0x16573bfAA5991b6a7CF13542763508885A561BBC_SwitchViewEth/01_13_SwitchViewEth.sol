// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "./SwitchRootEth.sol";
import "../ISwitchView.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SwitchViewEth is SwitchRootEth {
    using UniversalERC20 for IERC20;
    using UniswapExchangeLib for IUniswapExchange;
    function(CalculateArgs memory args) view returns(uint256[] memory)[PATHS_COUNT] pathFunctions = [
        calculate,
        calculateETH
    ];

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts
    )
        public
        override
        view
        returns (
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        (returnAmount, distribution) = _getExpectedReturn(
            ReturnArgs({
            fromToken: fromToken,
            destToken: destToken,
            amount: amount,
            parts: parts
            })
        );
    }

    function _getExpectedReturn(
        ReturnArgs memory returnArgs
    )
        internal
        view
        returns (
            uint256 returnAmount,
            uint256[] memory mergedDistribution
        )
    {

        uint256[] memory distribution = new uint256[](DEXES_COUNT*PATHS_COUNT*PATHS_SPLIT);
        mergedDistribution = new uint256[](DEXES_COUNT*PATHS_COUNT);

        if (returnArgs.fromToken == returnArgs.destToken) {
            return (returnArgs.amount, distribution);
        }

        int256[][] memory matrix = new int256[][](DEXES_COUNT*PATHS_COUNT*PATHS_SPLIT);
        bool atLeastOnePositive = false;
        for (uint l = 0; l < DEXES_COUNT; l++) {
            uint256[] memory rets;
            for (uint m = 0; m < PATHS_COUNT; m++) {
                for (uint k = 0; k < PATHS_SPLIT; k++) {
                    uint256 i = l*PATHS_COUNT*PATHS_SPLIT+m*PATHS_SPLIT+k;
                    rets = pathFunctions[m](CalculateArgs({
                        fromToken:returnArgs.fromToken,
                        destToken:returnArgs.destToken,
                        factory:IUniswapFactory(factories[l]),
                        amount:returnArgs.amount,
                        parts:returnArgs.parts
                    }));

                    // Prepend zero
                    matrix[i] = new int256[](returnArgs.parts + 1);
                    for (uint j = 0; j < rets.length; j++) {
                        matrix[i][j + 1] = int256(rets[j]);
                        atLeastOnePositive = atLeastOnePositive || (matrix[i][j + 1] > 0);
                    }
                }
            }
        }

        if (!atLeastOnePositive) {
            for (uint i = 0; i < DEXES_COUNT*PATHS_COUNT*PATHS_SPLIT;) {
                for (uint j = 1; j < returnArgs.parts + 1; j++) {
                    if (matrix[i][j] == 0) {
                        matrix[i][j] = VERY_NEGATIVE_VALUE;
                    }
                }
                unchecked {
                    i++;
                }
            }
        }
        (, distribution) = _findBestDistribution(returnArgs.parts, matrix);

        returnAmount = _getReturnByDistribution(Args({
                fromToken: returnArgs.fromToken,
                destToken: returnArgs.destToken,
                amount: returnArgs.amount,
                parts: returnArgs.parts,
                distribution: distribution,
                matrix: matrix,
                pathFunctions: pathFunctions,
                dexes: factories
            })
        );
        for (uint i = 0; i < DEXES_COUNT*PATHS_COUNT*PATHS_SPLIT;) {
            mergedDistribution[i/PATHS_SPLIT] += distribution[i];
            unchecked {
                i++;
            }
        }
        return (returnAmount, mergedDistribution);
    }

    struct Args {
        IERC20 fromToken;
        IERC20 destToken;
        uint256 amount;
        uint256 parts;
        uint256[] distribution;
        int256[][] matrix;
        function(CalculateArgs memory) view returns(uint256[] memory)[PATHS_COUNT] pathFunctions;
        IUniswapFactory[DEXES_COUNT] dexes;
    }

    function _getReturnByDistribution(Args memory args) internal view returns (uint256 returnAmount) {
        bool[DEXES_COUNT*PATHS_COUNT*PATHS_SPLIT] memory exact = [
        true,  // "Uniswap"
        true,  // "Uniswap (WETH)"
        true,  // "Uniswap"
        true,  // "Uniswap (WETH)"
        true, // Sushiswap
        true, // Sushiswap (WETH)
        true, // Sushiswap
        true, // Sushiswap (WETH)
        true, // Shibaswap
        true, // Shibaswap (WETH)
        true, // Shibaswap
        true // Shibaswap (WETH)
        ];

        for (uint i = 0; i < DEXES_COUNT*PATHS_COUNT*PATHS_SPLIT;) {
            if (args.distribution[i] > 0) {
                if (args.distribution[i] == args.parts || exact[i]) {
                    int256 value = args.matrix[i][args.distribution[i]];
                    returnAmount += uint256(
                            (value == VERY_NEGATIVE_VALUE ? int256(0) : value)
                        );
                }
                else {
                    uint256[] memory rets = args.pathFunctions[(i/PATHS_SPLIT)%PATHS_COUNT](CalculateArgs({
                    fromToken: args.fromToken,
                    destToken: args.destToken,
                    factory: args.dexes[i/(PATHS_COUNT*PATHS_SPLIT)],
                    amount: args.amount * args.distribution[i] / args.parts,
                    parts: 1
                    }));
                    returnAmount += rets[0];
                }
            }
            unchecked {
                i++;
            }
        }
    }

    // View Helpers
    struct Balances {
        uint256 src;
        uint256 dst;
    }

    function _linearInterpolation100(
        uint256 value,
        uint256 parts
    )
        internal
        pure
        returns (uint256[100] memory rets)
    {
        for (uint i = 0; i < parts; i++) {
            rets[i] = value * (i + 1) / parts;
        }
    }

    function _calculateUniswapFormula(
        uint256 fromBalance,
        uint256 toBalance,
        uint256 amount
    )
        internal
        pure
        returns (uint256)
    {
        if (amount == 0) {
            return 0;
        }
        return amount * toBalance * 997 / (
            fromBalance * 1000 + amount *997
        );
    }

    function calculate(CalculateArgs memory args) public view returns (uint256[] memory rets) {
        return _calculate(
            args.fromToken,
            args.destToken,
            args.factory,
            _linearInterpolation(args.amount, args.parts)
        );
    }

    function calculateETH(CalculateArgs memory args) internal view returns (uint256[] memory rets) {
        if (args.fromToken.isETH() || args.fromToken == weth || args.destToken.isETH() || args.destToken == weth) {
            return new uint256[](args.parts);
        }

        return _calculateOverMidToken(
            args.fromToken,
            weth,
            args.destToken,
            args.factory,
            args.amount,
            args.parts
        );
    }


    function _calculate(
        IERC20 fromToken,
        IERC20 destToken,
        IUniswapFactory factory,
        uint256[] memory amounts
    )
        internal
        view
        returns (uint256[] memory rets)
    {
        rets = new uint256[](amounts.length);

        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 destTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapExchange exchange = factory.getPair(fromTokenReal, destTokenReal);
        if (address(exchange) != address(0)) {
            uint256 fromTokenBalance = fromTokenReal.universalBalanceOf(address(exchange));
            uint256 destTokenBalance = destTokenReal.universalBalanceOf(address(exchange));
            for (uint i = 0; i < amounts.length; i++) {
                rets[i] = _calculateUniswapFormula(fromTokenBalance, destTokenBalance, amounts[i]);
            }
            return rets;
        }
    }

    function _calculateOverMidToken(
        IERC20 fromToken,
        IERC20 midToken,
        IERC20 destToken,
        IUniswapFactory factory,
        uint256 amount,
        uint256 parts
    )
        internal
        view
        returns (uint256[] memory rets)
    {
        rets = _linearInterpolation(amount, parts);

        rets = _calculate(fromToken, midToken, factory, rets);
        rets = _calculate(midToken, destToken, factory, rets);
        return rets;
    }

    function _calculateNoReturn(
        IERC20 /*fromToken*/,
        IERC20 /*destToken*/,
        uint256 /*amount*/,
        uint256 parts
    )
        internal
        view
        returns (uint256[] memory rets)
    {
        this;
        return new uint256[](parts);
    }
}