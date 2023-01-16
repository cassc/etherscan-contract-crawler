//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface IOriginationCore {
    // Function used by origination pools to send the origination fees to this contract
    function receiveFees() external payable;
}