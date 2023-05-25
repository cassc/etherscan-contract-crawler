// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IAntfarmRouter {
    function factory() external view returns (address);

    function WETH() external view returns (address);

    function antfarmToken() external view returns (address);

    struct swapParams {
        address[] path;
        uint16[] fees;
        address to;
    }

    struct swapExactTokensForTokensParams {
        uint256 amountIn;
        uint256 amountOutMin;
        uint256 maxFee;
        address[] path;
        uint16[] fees;
        address to;
        uint256 deadline;
    }

    function swapExactTokensForTokens(
        swapExactTokensForTokensParams calldata params
    ) external returns (uint256[] memory amounts);

    struct swapTokensForExactTokensParams {
        uint256 amountOut;
        uint256 amountInMax;
        uint256 maxFee;
        address[] path;
        uint16[] fees;
        address to;
        uint256 deadline;
    }

    function swapTokensForExactTokens(
        swapTokensForExactTokensParams calldata params
    ) external returns (uint256[] memory amounts);

    struct swapExactETHForTokensParams {
        uint256 amountOutMin;
        uint256 maxFee;
        address[] path;
        uint16[] fees;
        address to;
        uint256 deadline;
    }

    function swapExactETHForTokens(swapExactETHForTokensParams calldata params)
        external
        payable
        returns (uint256[] memory amounts);

    struct swapTokensForExactETHParams {
        uint256 amountOut;
        uint256 amountInMax;
        uint256 maxFee;
        address[] path;
        uint16[] fees;
        address to;
        uint256 deadline;
    }

    function swapTokensForExactETH(swapTokensForExactETHParams calldata params)
        external
        returns (uint256[] memory amounts);

    struct swapExactTokensForETHParams {
        uint256 amountIn;
        uint256 amountOutMin;
        uint256 maxFee;
        address[] path;
        uint16[] fees;
        address to;
        uint256 deadline;
    }

    function swapExactTokensForETH(swapExactTokensForETHParams calldata params)
        external
        returns (uint256[] memory amounts);

    struct swapETHForExactTokensParams {
        uint256 amountOut;
        uint256 maxFee;
        address[] path;
        uint16[] fees;
        address to;
        uint256 deadline;
    }

    function swapETHForExactTokens(swapETHForExactTokensParams calldata params)
        external
        payable
        returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        swapExactTokensForTokensParams calldata params
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        swapExactETHForTokensParams calldata params
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        swapExactTokensForETHParams calldata params
    ) external;

    // fetches and sorts the reserves for a pair
    function getReserves(
        address tokenA,
        address tokenB,
        uint16 fee
    ) external view returns (uint256 reserveA, uint256 reserveB);
}