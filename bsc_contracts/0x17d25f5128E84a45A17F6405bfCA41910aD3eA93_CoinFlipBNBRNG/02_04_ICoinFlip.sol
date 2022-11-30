// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICoinFlip {
    
    function autoFlip(uint256 _sessionId, uint8 _flipResult) external;
    
}