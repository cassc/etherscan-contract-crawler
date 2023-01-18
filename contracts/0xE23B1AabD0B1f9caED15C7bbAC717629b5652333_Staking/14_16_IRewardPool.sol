// SPDX-License-Identifier:MIT	
pragma solidity ^0.8.0;
interface IRewardPool{
    function wave() external;
    function waveAmount() view external returns (uint);
}