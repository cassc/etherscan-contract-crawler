// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface ITreasury {
    function distribute(address _receiver, uint256 _amount) external;

    function distributeToken(address _receiver, address _tokenOut, uint256 _lpAmount, uint256 _minAmountOut) external;
}