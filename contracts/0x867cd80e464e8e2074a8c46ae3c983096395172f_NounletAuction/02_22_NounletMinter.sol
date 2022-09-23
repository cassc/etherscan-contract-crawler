// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {INounletMinter as IMinter, Permission} from "../interfaces/INounletMinter.sol";
import {INounletSupply as ISupply} from "../interfaces/INounletSupply.sol";
import {IVault} from "../interfaces/IVault.sol";

/// @title NounletMinter
/// @author Tessera
/// @notice Module contract for minting new fractions
contract NounletMinter is IMinter {
    /// @notice Address of NounletSupply target contract
    address public immutable supply;

    /// @dev Initializes NounletSupply target contract
    constructor(address _supply) {
        supply = _supply;
    }

    /// @notice Gets the list of leaf nodes used to generate a merkle tree
    /// @dev Leaf nodes are hashed permissions of the merkle tree
    /// @return nodes A list of leaf nodes
    function getLeafNodes() external view returns (bytes32[] memory nodes) {
        // Gets list of permissions from this module
        Permission[] memory permissions = getPermissions();
        nodes = new bytes32[](permissions.length);
        for (uint256 i; i < permissions.length; ) {
            // Hashes permission into leaf node
            nodes[i] = keccak256(abi.encode(permissions[i]));
            // Can't overflow since loop is a fixed size
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Gets the list of permissions installed on a vault
    /// @dev Permissions consist of a module contract, target contract, and function selector
    /// @return permissions A list of Permission Structs
    function getPermissions() public view returns (Permission[] memory permissions) {
        permissions = new Permission[](1);
        // Mint function selector from supply contract
        permissions[0] = Permission(address(this), supply, ISupply.mint.selector);
    }

    /// @notice Mints a single fraction
    /// @param _vault Address of the Vault
    /// @param _to Address of the receiver
    /// @param _id ID of the fractional token
    /// @param _mintProof Merkle proof for minting fractions
    function _mintFraction(
        address _vault,
        address _to,
        uint256 _id,
        bytes32[] calldata _mintProof
    ) internal {
        bytes memory data = abi.encodeCall(ISupply.mint, (_to, _id));
        IVault(payable(_vault)).execute(supply, data, _mintProof);
    }
}