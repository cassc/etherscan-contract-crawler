// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IRewardHandler {
    function sell() external;

    function setPendingOwner(address _po) external;

    function applyPendingOwner() external;

    function rescueToken(address _token, address _to) external;
}