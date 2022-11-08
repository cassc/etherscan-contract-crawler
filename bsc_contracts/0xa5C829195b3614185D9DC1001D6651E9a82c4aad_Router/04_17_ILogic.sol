// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILogic {
    function COLLATERAL_TOKEN() external view returns (address);
    function N_TOKENS() external view returns (uint);
    function PRICE_ORACLE() external view returns (address);
    function BASE_TOKEN_0() external view returns (bool);
    function POOL() external view returns (address);
    function getDTokenInfo(uint idx) external view returns (bytes32, bytes32, uint8);
    function deleverage(uint224 start, uint224 end) external returns (uint224 mid);
    function swap(address tokenIn, address tokenOut) external returns (uint amountOut, bool needVerifying);
    function verify() external;
    // function getAmountOut(address tokenIn, address tokenOut, uint amountIn) external view returns (uint amountOut);
    function getStates() external view returns (
        uint Rc,
        uint basePriceCumulative,
        uint32 blockTimestamp,
        uint224 baseTWAP,
        uint32 priceScaleTimestamp,
        uint224 priceScaleLong,
        uint224 priceScaleShort
    );
}