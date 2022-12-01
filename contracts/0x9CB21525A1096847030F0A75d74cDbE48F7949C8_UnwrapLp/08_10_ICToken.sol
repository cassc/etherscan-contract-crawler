// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

interface ICToken {
    function balanceOf(address owner) external view returns (uint256);

    function redeem(uint redeemTokens) external returns (uint);
}