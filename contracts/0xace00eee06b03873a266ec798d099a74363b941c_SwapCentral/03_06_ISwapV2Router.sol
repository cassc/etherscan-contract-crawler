// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

interface ISwapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    //token exact amount in, token -> token 1
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    //token exact amount out, token -> token 2
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    //ETH exact amount in, exact ETH -> token 3
    function swapExactETHForTokens
    (uint amountOutMin, 
    address[] calldata path, 
    address to, 
    uint deadline
    ) external payable returns (uint[] memory amounts);

    //ETH exact amount out, token -> exact ETH 4
    function swapTokensForExactETH(
        uint amountOut, 
        uint amountInMax, 
        address[] calldata path, 
        address to, 
        uint deadline
        ) external returns (uint[] memory amounts);


    // token exact amount in, exact token -> ETH 5
    function swapExactTokensForETH(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
        )
        external
        returns (uint[] memory amounts);

    // token exact amout out, ETH -> exact token 6
    function swapETHForExactTokens(
        uint amountOut, 
        address[] calldata path, 
        address to, 
        uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    // calculate maximum output token, useful for exact token -> token
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    // calculate minimum input token, useful for token -> exact token
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}