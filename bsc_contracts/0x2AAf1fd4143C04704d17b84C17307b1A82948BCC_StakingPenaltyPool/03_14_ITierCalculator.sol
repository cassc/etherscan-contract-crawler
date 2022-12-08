// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ITierCalculator {

    function getTierIndex(address _user, address _deal)
    external
    view
    returns (bool success, uint256 tierIndex);

    function resetStartOnce(address _user) external;

    function resetStart(address _user) external;

    function userLockingStarts(address _user) external view returns (uint256);
}