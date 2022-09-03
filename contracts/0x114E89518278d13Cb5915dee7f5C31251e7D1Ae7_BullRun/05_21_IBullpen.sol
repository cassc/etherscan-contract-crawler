// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBullpen {
    
    function bullCount() external view returns (uint16);
    function receiveBull(address _originalOwner, uint16 _id) external;
    function returnBullToOwner(address _returnee, uint16 _id) external;
    function getBullOwner(uint16 _id) external view returns (address);
    function selectRandomBullOwnerToReceiveStolenRunner(uint256 seed) external returns (address);
    function stealBull(address _thief, uint16 _id) external;

}