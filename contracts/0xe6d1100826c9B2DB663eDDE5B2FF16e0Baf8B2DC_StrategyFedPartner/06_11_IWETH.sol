// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
import "IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function decimals() external view returns (uint256);

    function withdraw(uint256) external;
}