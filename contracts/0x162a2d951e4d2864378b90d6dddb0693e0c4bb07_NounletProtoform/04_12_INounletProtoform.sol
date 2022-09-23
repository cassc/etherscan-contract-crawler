// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for NounletProtoform contract
interface INounletProtoform {
    /// @dev Event log for modules that are enabled on a vault
    /// @param _vault Address of the vault deployed
    /// @param _modules List of modules contract addresses being activated on the vault
    event ActiveModules(address indexed _vault, address[] _modules);

    function auction() external view returns (address);

    function deployVault(
        address[] calldata _modules,
        address[] calldata _plugins,
        bytes4[] calldata _selectors,
        bytes32[] calldata _mintProof,
        address _descriptor,
        uint256 _nounId
    ) external returns (address vault);

    function generateMerkleTree(address[] calldata _modules)
        external
        view
        returns (bytes32[] memory hashes);

    function registry() external view returns (address);
}