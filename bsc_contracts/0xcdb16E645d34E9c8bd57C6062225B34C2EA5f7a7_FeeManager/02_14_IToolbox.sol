// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IToolbox {

    function getTokenBUSDValue(uint256 tokenBalance, address token, bool isLPToken) external view returns (uint256);

}