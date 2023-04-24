// SPDX-License-Identifier: CC BY-NC 2.0
pragma solidity ^0.8.9;

interface ICicleoSubscriptionRouter {
    function taxAccount() external view returns (address);
}