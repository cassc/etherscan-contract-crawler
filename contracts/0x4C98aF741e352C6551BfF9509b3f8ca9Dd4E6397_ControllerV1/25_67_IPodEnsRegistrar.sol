pragma solidity ^0.8.7;

interface IPodEnsRegistrar {
    function ens() external view returns (address);

    function resolver() external view returns (address);

    function reverseRegistrar() external view returns (address);

    function getRootNode() external view returns (bytes32);

    function registerPod(
        bytes32 label,
        address podSafe,
        address podCreator
    ) external returns (address);

    function register(bytes32 label, address owner) external;

    function deregister(address safe, bytes32 label) external;

    function setText(
        bytes32 node,
        string calldata key,
        string calldata value
    ) external;

    function setAddr(bytes32 node, address newAddress) external;

    function addressToNode(address input) external returns (bytes32);

    function getEnsNode(bytes32 label) external view returns (bytes32);
}