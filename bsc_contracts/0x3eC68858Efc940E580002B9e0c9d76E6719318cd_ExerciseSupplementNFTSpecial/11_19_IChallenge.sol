// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IChallenge {
    /**
     * @notice get status of challenge
     * @return true: challenge finish
     * false: challenge in progess
     */
    
    function isFinished() external view returns(bool);

}