// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IAMPERStaking {
    
    function deposit(uint _userId, uint _amount, uint _outOfStakingAmount) external;
    
    function income(uint _userId) external view returns(uint);

}