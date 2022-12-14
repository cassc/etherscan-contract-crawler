// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;


interface IStorageContract {

    struct InstanceInfo {
        string name;
        string symbol;
        address creator;
    }

    function addInstance(
        address instanceAddress,
        address creator,
        string memory name,
        string memory symbol
    ) external returns (uint256);
    function factory() external view returns(address);
    function getInstanceInfo() external view returns(InstanceInfo memory);
    function getInstance(bytes32 hash) external view returns(address);
    function instancesCount() external view returns (uint256);

}