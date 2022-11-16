pragma solidity ^0.8.0;

interface ICallback {
    function fulfill(bytes32 requestId, bytes memory gameData) external;
}