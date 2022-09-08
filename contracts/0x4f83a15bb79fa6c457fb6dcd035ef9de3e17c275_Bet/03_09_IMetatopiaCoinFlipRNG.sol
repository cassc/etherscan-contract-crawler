// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMetatopiaCoinFlipRNG {
    
    function oneOutOfTwo() external view returns (uint256);
    function requestRandomWords() external;
    
}