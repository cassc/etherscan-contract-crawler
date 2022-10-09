// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRule {
    /* State Variables Getter */
    function DISCOUNT() external view returns (uint256);
    function BASE() external view returns (uint256);

    /* View Functions */
    function verify(address) external view returns (bool);
    function calDiscount(address) external view returns (uint256);
}