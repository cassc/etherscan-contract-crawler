// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for generic Protoform contract
interface IProtoform {
    /// @dev Event log for modules that are enabled on a vault
    /// @param _vault The vault deployed
    /// @param _modules The modules being activated on deployed vault
    event ActiveModules(address indexed _vault, address[] _modules);

    function generateMerkleTree(address[] memory _modules)
        external
        view
        returns (bytes32[] memory tree);

    function generateUnhashedMerkleTree(address[] memory _modules)
        external
        view
        returns (bytes[] memory tree);
}