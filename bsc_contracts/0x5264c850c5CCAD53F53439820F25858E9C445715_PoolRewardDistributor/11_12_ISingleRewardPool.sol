// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/**
* @title Interface that can be used to interact with single reward pool contracts.
*/
interface ISingleRewardPool {
    function notifyRewardAmount(uint256 reward) external;
}