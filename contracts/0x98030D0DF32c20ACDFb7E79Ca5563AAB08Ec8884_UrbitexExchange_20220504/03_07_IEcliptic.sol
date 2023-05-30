// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IEcliptic {
    function isApprovedForAll(address, address) external returns (bool);
    function transferFrom(address, address, uint256) external;
    function spawn(uint32, address) external;
    function transferPoint(uint32, address, bool) external;
    function setTransferProxy(uint32, address) external;


}