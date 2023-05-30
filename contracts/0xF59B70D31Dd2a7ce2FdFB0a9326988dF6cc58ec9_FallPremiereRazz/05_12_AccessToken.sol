// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface AccessToken {
    function balanceOf(address wallet) external returns (uint256);
}