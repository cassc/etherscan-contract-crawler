pragma solidity 0.8.6;

interface AmbInterface {
    function executeSignatures(bytes memory _data, bytes memory _signatures) external;
    function safeExecuteSignatures(bytes memory _data, bytes memory _signatures) external;

}