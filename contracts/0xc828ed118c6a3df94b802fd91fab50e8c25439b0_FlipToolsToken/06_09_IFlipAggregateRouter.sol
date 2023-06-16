// SPDX-License-Identifier: MIT
//Twitter: https://twitter.com/FLIP_Tools

pragma solidity ^0.8.0;

interface IFlipAggregateRouter {
    function zeroAdd() external view returns (address);

    function deadAdd() external view returns (address);

    function deployer() external view returns (address);

    function checkDexActive(uint version, uint256 dexID) external view returns (bool);

    function getRouter(uint version, uint256 dexID) external view returns (address);

    function addRouter(uint version, uint256 dexID, address routerAdd) external;

    function blockRouter(uint version, uint256 dexID) external;

    function swapV2ETH(address token, uint256 amount, uint256 dexID, bool isSell) external payable returns(uint[] memory amountsOut);

    function swapV2WETH(address token, uint256 amount, uint256 dexID, bool isSell) external returns (uint[] memory amountsOut);

    function swapV3WETH(address token, uint256 amount, uint256 dexID, uint24 poolFee, bool isSell) external returns (uint256 amountOut);

    function swapV3ETH(address token, uint256 amount, uint256 dexID, uint24 poolFee, bool isSell) external payable returns (uint256 amountOut);

}