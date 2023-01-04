pragma solidity ^0.8.9;

interface ICommLayer {
    function sendMsg(
        address,
        bytes memory,
        bytes memory
    ) external payable;
}