//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


struct ApplicationEventStruct {
    bytes32 selector;
    string name;
    bytes params;
}

interface IEventReportingContract {
    event ApplicationEvent(address indexed account, address indexed _contract, bytes32 indexed selector, string name, bytes params);
}