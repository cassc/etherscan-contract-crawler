pragma solidity ^0.8.0;

interface IPancakeRouter02Reader {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}