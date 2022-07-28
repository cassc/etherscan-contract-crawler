pragma solidity 0.4.24;

interface IKernelEvents {
    event SetApp(bytes32 indexed namespace, bytes32 indexed appId, address app);
}