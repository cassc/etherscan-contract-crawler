// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPool {
    function addLiquidity(address user_, uint256 amountLD_) external;

    function removeLiquidity(address user_, uint256 amountLD_) external;

    function removeLiquidityTo(address user_, uint256 amountLD_, address to_) external;

    function deposit(address user_, uint256 amountLD_) external returns (uint256 amountSD);

    function withdraw(address user_, uint256 amountSD_) external returns (uint256 amountLD);

    function token() external returns (address token);

    function convertRate() external returns (uint256 convertRate);
}