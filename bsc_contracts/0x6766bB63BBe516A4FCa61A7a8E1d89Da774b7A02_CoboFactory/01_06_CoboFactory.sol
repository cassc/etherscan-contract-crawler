// deployscript 5107fcb7552eafd7f45e5d52da8b277e6844dc1b
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "Clones.sol";

import "BaseOwnable.sol";

contract CoboFactory is BaseOwnable {
    bytes32 public constant NAME = "CoboFactory";
    uint256 public constant VERSION = 1;

    mapping(bytes32 => address) public latestImplementations;
    mapping(bytes32 => address[]) public allImplementations;

    event ProxyCreated(address indexed deployer, bytes32 indexed name, address indexed implementation, address proxy);
    event ImplementationAdded(bytes32 indexed name, address indexed implementation);

    // deployer => name => proxy contract list
    mapping(address => mapping(bytes32 => address[])) public records;

    constructor(address _owner) BaseOwnable(_owner) {}

    /// View functions.
    function getLatestImplementation(bytes32 name) public view returns (address impl) {
        impl = latestImplementations[name];
        require(impl != address(0), "No implementation");
    }

    function getLastRecord(address deployer, bytes32 name) external view returns (address proxy) {
        address[] storage record = records[deployer][name];
        require(record.length > 0, "No record");
        proxy = record[record.length - 1];
    }

    function getRecordSize(address deployer, bytes32 name) external view returns (uint256 size) {
        address[] storage record = records[deployer][name];
        size = record.length;
    }

    function getAllRecord(address deployer, bytes32 name) external view returns (address[] memory proxies) {
        return records[deployer][name];
    }

    function getRecords(
        address deployer,
        bytes32 name,
        uint256 start,
        uint256 end
    ) external view returns (address[] memory proxies) {
        address[] storage record = records[deployer][name];
        uint256 size = record.length;
        if (end > size) end = size;
        require(end > start, "end >= start");
        proxies = new address[](end - start);
        for (uint i = start; i < end; ++i) {
            proxies[i - start] = record[i];
        }
    }

    function getCreate2Address(bytes32 name, bytes32 salt) external view returns (address instance) {
        address implementation = getLatestImplementation(name);
        return Clones.predictDeterministicAddress(implementation, salt);
    }

    /// External functions.

    /// @dev Create EIP 1167 proxy and call (often initialize) function.
    function create(bytes32 name) public returns (address instance) {
        address implementation = getLatestImplementation(name);
        instance = Clones.clone(implementation);
        emit ProxyCreated(msg.sender, name, implementation, instance);
    }

    /// @dev Create with create2
    function create2(bytes32 name, bytes32 salt) public returns (address instance) {
        address implementation = getLatestImplementation(name);
        instance = Clones.cloneDeterministic(implementation, salt);
        emit ProxyCreated(msg.sender, name, implementation, instance);
    }

    function createAndRecord(bytes32 name) external returns (address instance) {
        instance = create(name);
        records[msg.sender][name].push(instance);
    }

    function create2AndRecord(bytes32 name, bytes32 salt) public returns (address instance) {
        instance = create2(name, salt);
        records[msg.sender][name].push(instance);
    }

    // Owner functions.
    function addImplementation(address impl) external onlyOwner {
        bytes32 name = IVersion(impl).NAME();
        latestImplementations[name] = impl;
        allImplementations[name].push(impl);
        emit ImplementationAdded(name, impl);
    }
}