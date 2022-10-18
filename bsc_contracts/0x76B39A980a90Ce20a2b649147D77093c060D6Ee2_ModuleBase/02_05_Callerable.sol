// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

contract Callerable is Ownable {

    struct CallerData{
        address caller;
        bool isCaller;
    }
    uint32 internal callerCount;
    mapping(address => bool) internal mapCaller;
    mapping(uint32 => CallerData) internal mapCallerList;

    modifier onlyCaller {
        // if(!auth.getDebugMode()) {
        //     require(mapCaller[msg.sender], "caller only");
        //     _;
        // } else {
        //     _;
        // }
        require(mapCaller[msg.sender], "caller only");
        _;
    }

    constructor(address _auth) Ownable(_auth) {
    }

    function addCaller(address _caller) external onlyOwner {
        require(!mapCaller[_caller], "caller exists");
        mapCaller[_caller] = true;
        mapCallerList[++callerCount] = CallerData(_caller, true);
    }

    function isCaller(address addr) external view returns (bool res) {
        res = _isCaller(addr);
    }

    function _isCaller(address addr) internal view returns (bool res) {
        res = mapCaller[addr];
    }

    function getCallerCount() external view returns (uint32 res) {
        res = callerCount;
    }

    function removeCaller(address addr) external onlyOwner {
        if(mapCaller[addr]) {
            delete mapCaller[addr];
            for(uint32 i = 1; i <= callerCount; ++i) {
                if(mapCallerList[i].caller == addr) {
                    CallerData storage cd = mapCallerList[i];
                    cd.isCaller = false;
                    break;
                }
            }
        }
    }

    function getCaller(uint32 index) external view returns (bool res, address addr) {
        addr = mapCallerList[index].caller;
        res = mapCaller[addr];
    }
}