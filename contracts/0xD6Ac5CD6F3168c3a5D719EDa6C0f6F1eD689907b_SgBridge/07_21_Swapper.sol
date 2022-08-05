//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface Swapper {
    function swap(address tokenA, address tokenB, uint256 amount, address recipient) external payable returns (uint256);
    function quote(address tokenA, address tokenB, uint256 amount) external returns (uint256);
    function isTokenSupported(address bridgeToken, address token) external view returns(bool);
    function isTokensSupported(address bridgeToken, address[] memory tokens) external view returns(bool[] memory);
    function isPairsSupported(address[][] calldata tokens) external view returns(bool[] memory);
}