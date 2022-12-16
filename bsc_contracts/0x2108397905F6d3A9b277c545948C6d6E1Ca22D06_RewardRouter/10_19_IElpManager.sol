// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IElpManager {
    function cooldownDuration() external returns (uint256);
    function lastAddedAt(address _account) external returns (uint256);
    function addLiquidity(address _token, uint256 _amount, uint256 _minUsdx, uint256 _minElp) external returns (uint256);
    function removeLiquidity(address _tokenOut, uint256 _elpAmount, uint256 _minOut, address _receiver) external returns (uint256);
    // function removeLiquidityForAccount(address _account, address _tokenOut, uint256 _elpAmount, uint256 _minOut, address _receiver) external returns (uint256);
}