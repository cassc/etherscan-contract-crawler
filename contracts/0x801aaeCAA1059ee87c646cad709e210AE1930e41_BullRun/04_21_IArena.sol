// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IArena {
    
    function matadorCount() external view returns (uint16);
    function receiveMatador(address _originalOwner, uint16 _id) external;
    function returnMatadorToOwner(address _returnee, uint16 _id) external;
    function getMatadorOwner(uint16 _id) external view returns (address);
    function selectRandomMatadorOwnerToReceiveStolenBull(uint256 seed) external view returns (address);
    
}