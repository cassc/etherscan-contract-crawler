// master ef75b8f4c5758dd853427af1d35a454d7587c7a2
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "Clones.sol";

import "BaseOwnable.sol";

/// @title CoboFactory - A contract factory referenced by bytes32 name.
/// @author Cobo Safe Dev Team https://www.cobo.com/
/// @notice Mostly used to manage proxy logic contract. But ok to manage non-proxy contracts.
/// @dev Contracts to add should extend IVersion interface, which implement `NAME()` function.
contract CoboFactory is BaseOwnable {
    bytes32 public constant NAME = "CoboFactory";
    uint256 public constant VERSION = 1;

    bytes32[] public names;

    // The last one added.
    mapping(bytes32 => address) public latestImplementations;

    // Name => All added contracts.
    mapping(bytes32 => address[]) public implementations;

    // deployer => name => proxy contract list
    // This is expensive. Query ProxyCreated event in SubGraph is a better solution.
    mapping(address => mapping(bytes32 => address[])) public records;

    event ProxyCreated(address indexed deployer, bytes32 indexed name, address indexed implementation, address proxy);
    event ImplementationAdded(bytes32 indexed name, address indexed implementation);

    constructor(address _owner) BaseOwnable(_owner) {}

    function _getLatestImplStrict(bytes32 name) internal view returns (address impl) {
        impl = getLatestImplementation(name);
        require(impl != address(0), "No implementation");
    }

    /// View functions.
    function getLatestImplementation(bytes32 name) public view returns (address impl) {
        impl = latestImplementations[name];
    }

    function getAllImplementations(bytes32 name) external view returns (address[] memory impls) {
        impls = implementations[name];
    }

    function getAllNames() external view returns (bytes32[] memory _names) {
        _names = names;
    }

    /// @dev For etherscan view.
    function getNameString(uint i) public view returns (string memory _name) {
        _name = string(abi.encodePacked(names[i]));
    }

    function getAllNameStrings() external view returns (string[] memory _names) {
        _names = new string[](names.length);
        for (uint i = 0; i < names.length; ++i) {
            _names[i] = getNameString(i);
        }
    }

    function getLastRecord(address deployer, bytes32 name) external view returns (address proxy) {
        address[] storage record = records[deployer][name];
        if (record.length == 0) return address(0);
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
        require(end > start, "end > start");
        proxies = new address[](end - start);
        for (uint i = start; i < end; ++i) {
            proxies[i - start] = record[i];
        }
    }

    function getCreate2Address(address creator, bytes32 name, bytes32 salt) external view returns (address instance) {
        address implementation = getLatestImplementation(name);
        if (implementation == address(0)) return address(0);
        salt = keccak256(abi.encode(creator, salt));
        return Clones.predictDeterministicAddress(implementation, salt);
    }

    /// External functions.

    /// @dev Create EIP 1167 proxy.
    function create(bytes32 name) public returns (address instance) {
        address implementation = _getLatestImplStrict(name);
        instance = Clones.clone(implementation);
        emit ProxyCreated(msg.sender, name, implementation, instance);
    }

    /// @dev Create EIP 1167 proxy with create2.
    function create2(bytes32 name, bytes32 salt) public returns (address instance) {
        address implementation = _getLatestImplStrict(name);
        salt = keccak256(abi.encode(msg.sender, salt));
        instance = Clones.cloneDeterministic(implementation, salt);
        emit ProxyCreated(msg.sender, name, implementation, instance);
    }

    /// @notice Create and record the creation in contract.
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

        // If new name found, add to `names`.
        if (latestImplementations[name] == address(0)) {
            names.push(name);
        }

        latestImplementations[name] = impl;
        implementations[name].push(impl);
        emit ImplementationAdded(name, impl);
    }
}