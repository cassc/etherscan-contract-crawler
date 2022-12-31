// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.9;

/// @title The interface of Nash21Manager
/// @notice Handles the configuration of Nash21 ecosystem
/// @dev Controls addresses, IDs, deployments, upgrades, proxies, access control and pausability
interface INash21Manager {
    /// @notice Emitted when a new address with ID is setted
    /// @param id Address identifier
    /// @param addr Address
    event NewId(bytes32 indexed id, address addr);

    /// @notice Emitted when a new address with ID is setted
    /// @param id Address identifier
    /// @param proxy New deployed UUPS
    /// @param implementation Proxy's implementation
    /// @param upgrade Whether or not was an upgrade or not
    event Deployment(
        bytes32 indexed id,
        address indexed proxy,
        address implementation,
        bool upgrade
    );

    /// @notice Emitted when an ID is locked for changes
    /// @param id Address identifier
    /// @param addr Address
    event Locked(bytes32 indexed id, address addr);

    /// @notice Deploy a UUPS Proxy and its implementation
    /// @dev If proxy is already deployed upgrades the implementation
    /// @param id Address identifier
    /// @param bytecode Bytecode of the implementation
    /// @param initializeCalldata Encoded initialize calldata
    /// @return implementation Address of the implementation
    function deploy(
        bytes32 id,
        bytes calldata bytecode,
        bytes calldata initializeCalldata
    ) external returns (address implementation);

    /// @notice Deploy a UUPS Proxy with an already deployed implementation
    /// @param id Address identifier
    /// @param implementation Address of the implementation
    /// @param initializeCalldata Encoded initialize calldata
    function deployProxyWithImplementation(
        bytes32 id,
        address implementation,
        bytes calldata initializeCalldata
    ) external;

    /// @notice Returns address of an ID
    /// @param id Address identifier
    /// @return Address of ID
    function get(bytes32 id) external view returns (address);

    /// @notice Returns address of the implementation of a proxy
    /// @param proxy Address of the proxy
    /// @return Implemenation
    function implementationByProxy(address proxy)
        external
        view
        returns (address);

    /// @notice Locks and ID for changes
    /// @param id Address identifier
    function lock(bytes32 id) external;

    /// @notice Returns whether or not an ID is locked
    /// @param id Address of the proxy
    /// @return True for locked false for not locked
    function locked(bytes32 id) external view returns (bool);

    /// @notice Returns ID linked to a proxy
    /// @param proxy Address of the proxy
    /// @return Identificator
    function name(address proxy) external view returns (bytes32);

    /// @notice Sets address linked to an ID
    /// @param id Address identifier
    /// @param addr Address
    function setId(bytes32 id, address addr) external;

    /// @notice Upgrades implementation of an UUPS proxy
    /// @param id Address identifier
    /// @param implementation Address of the implementation
    /// @param initializeCalldata Encoded initialize calldata
    function upgrade(
        bytes32 id,
        address implementation,
        bytes calldata initializeCalldata
    ) external;
}