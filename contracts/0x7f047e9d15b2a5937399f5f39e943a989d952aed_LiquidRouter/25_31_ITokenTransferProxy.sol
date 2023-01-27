// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface ITokenTransferProxy {
    function transferFrom(address token, address from, address to, uint256 amount) external;
}