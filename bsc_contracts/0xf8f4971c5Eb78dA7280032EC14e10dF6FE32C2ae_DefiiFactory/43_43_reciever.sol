// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract TestReciever {
    event FunctionCall(bytes data, uint256 value);

    function call() payable external {
        emit FunctionCall(abi.encodeWithSignature("call()"), msg.value);
    }

    function callWithParams(address param1, uint256 param2) payable external {
        emit FunctionCall(abi.encodeWithSignature("callWithParams(address,uint256)", param1, param2), msg.value);
    }

    receive() external payable {
        emit FunctionCall(bytes(""), msg.value);
    }
}