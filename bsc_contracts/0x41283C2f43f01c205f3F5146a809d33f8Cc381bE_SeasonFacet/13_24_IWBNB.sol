/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title WBNB Interface
 **/
interface IWBNB is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}