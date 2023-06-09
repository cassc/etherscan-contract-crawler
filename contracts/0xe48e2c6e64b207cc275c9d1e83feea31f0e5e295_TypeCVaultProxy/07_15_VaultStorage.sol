//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract VaultStorage  {

    string public name;

    uint256 public totalAllocatedAmount;

    uint256 public totalClaimCounts;

    uint256 public nowClaimRound = 0;

    uint256 public totalClaimsAmount;

    uint256[] public claimTimes;
    uint256[] public claimAmounts;
    // uint256[] public addAmounts;

    bool public pauseProxy;

    mapping(uint256 => address) public proxyImplementation;
    mapping(address => bool) public aliveImplementation;
    mapping(bytes4 => address) public selectorImplementation;

    bool public boolLogEvent ;
    address public logEventAddress ;

    function allClaimInfos() external view returns (uint256, uint256[] memory, uint256[] memory, uint256){
         return (totalClaimCounts, claimTimes, claimAmounts, nowClaimRound);
    }

}