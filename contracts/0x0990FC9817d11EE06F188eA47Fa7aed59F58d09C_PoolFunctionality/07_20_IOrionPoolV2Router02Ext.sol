pragma solidity >=0.6.2;

interface IOrionPoolV2Router02Ext {
    function swapExactTokensForTokensAutoRoute(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to
    ) external payable returns (uint[] memory amounts);
    function swapTokensForExactTokensAutoRoute(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to
    ) external payable returns (uint[] memory amounts);

}