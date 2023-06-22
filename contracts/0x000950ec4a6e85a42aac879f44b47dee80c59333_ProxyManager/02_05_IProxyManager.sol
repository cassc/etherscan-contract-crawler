// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IProxyManager {
    function ID(string memory _string) external pure returns (bytes32);

    function instances(bytes32 id, uint256 i) external view returns (address);

    function instances(
        string memory id,
        uint256 i
    ) external view returns (address);

    function contractOf(address clone) external view returns (bytes32);

    function create(
        bytes32 contract_id,
        bytes memory init_data
    ) external payable returns (address clone_address);

    function createStr(
        string memory contract_id,
        bytes memory init_data
    ) external payable returns (address clone_address);

    function setImplementation(
        bytes32 logic_type,
        address logic_contract,
        bytes calldata upgrade_data
    ) external;

    function setImplementationStr(
        string memory implementation_id,
        address implementation,
        bytes calldata upgrade_data
    ) external;

    function implementationOf(bytes32 id) external returns (address);

    function implementationOfStr(string memory id) external returns (address);
}