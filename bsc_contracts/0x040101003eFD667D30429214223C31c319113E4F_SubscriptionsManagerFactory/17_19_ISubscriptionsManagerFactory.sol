// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface ISubscriptionsManagerFactory {
    function doCharge(address token, uint256 amount, address from, address to) external returns(bool success);
}