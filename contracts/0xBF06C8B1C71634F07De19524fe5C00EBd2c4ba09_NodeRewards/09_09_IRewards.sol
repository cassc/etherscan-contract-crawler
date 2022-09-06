// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

interface IRewards {
    function registerUserAction(address user) external;

    function setNewAPR(uint256 _apr) external;
}