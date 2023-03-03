// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface ISubscriptionsHook {
    function onCharge(address token, uint256 amount) external;
}