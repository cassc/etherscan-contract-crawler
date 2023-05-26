pragma solidity >=0.6.2;

interface ISwapper {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

		function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

}