// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

interface ITokenDelegate {

    function moveSpendingPower(address src, address dst, uint256 amount) external;
}