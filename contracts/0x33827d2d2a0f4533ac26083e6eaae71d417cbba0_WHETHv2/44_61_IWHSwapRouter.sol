// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

interface IWHSwapRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForTokensAndWrap(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to, 
        uint deadline,
        uint protectionPeriod,
        bool mintToken,
        uint minUSDCPremium
    ) external returns (uint[] memory amounts, uint newTokenId);

    function swapTokensForExactTokensAndWrap(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline,
        uint protectionPeriod, 
        bool mintToken,
        uint minUSDCPremium
    ) external returns (uint[] memory amounts, uint newTokenId);

    function swapExactETHForTokensAndWrap(uint amountOutMin, address[] calldata path, address to, uint deadline, uint protectionPeriod, bool mintToken, uint minUSDCPremium)
        external
        payable
        returns (uint[] memory amounts, uint newTokenId);

    function swapETHForExactTokensAndWrap(uint amountOut, address[] calldata path, address to, uint deadline, uint protectionPeriod, bool mintToken, uint minUSDCPremium)
        external
        payable
        returns (uint[] memory amounts, uint newTokenId);


    function swapExactTokensForETHAndWrap(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, uint protectionPeriod, bool mintToken, uint minUSDCPremium)
        external
        returns(uint[] memory amounts, uint newTokenId);

    function swapTokensForExactETHAndWrap(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline, uint protectionPeriod, bool mintToken, uint minUSDCPremium)
        external
        returns (uint[] memory amounts, uint newTokenId);

// **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        external
        pure
        returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        external
        pure        
        returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] memory path)
        external
        view        
        returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] memory path)
        external
        view
        returns (uint[] memory amounts);
}