// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ICompetitionVault {
    
    function autoSettleComp(uint256 _id, uint256 seed) external;
    
}