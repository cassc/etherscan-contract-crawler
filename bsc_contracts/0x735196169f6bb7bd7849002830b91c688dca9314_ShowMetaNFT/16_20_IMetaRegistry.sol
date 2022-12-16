// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMetaRegistry {
    function getInterfaceImplementer(address _addr, bytes32 _interfaceHash)
        external
        view
        returns (address);

    function setInterfaceImplementer(
        address _addr,
        bytes32 _interfaceHash,
        address _implementer
    ) external;

    function setManager(address _addr, address _newManager) external;

    function getManager(address _addr) external view returns (address);

    function interfaceHash(string calldata _interfaceName)
        external
        pure
        returns (bytes32);
}