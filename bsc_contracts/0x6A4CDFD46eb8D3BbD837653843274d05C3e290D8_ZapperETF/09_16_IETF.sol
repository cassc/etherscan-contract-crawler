// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IETF {
    /* View methods */
    function native() external view returns (address);

    /* Non-view methods */
    function join(uint256 amountIn) external returns (uint256 mintAmount);
    function exit(uint256 amountIn) external returns (uint256 amountOut);
}