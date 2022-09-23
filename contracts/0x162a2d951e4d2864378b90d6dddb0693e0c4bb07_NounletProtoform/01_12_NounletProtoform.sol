// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {MerkleBase} from "./utils/MerkleBase.sol";
import {INounletAuction as IAuction, IModule} from "./interfaces/INounletAuction.sol";
import {INounletProtoform as IProtoform} from "./interfaces/INounletProtoform.sol";
import {INounletRegistry as IRegistry} from "./interfaces/INounletRegistry.sol";
import {INounsToken as INouns} from "./interfaces/INounsToken.sol";

/// @title NounletProtoform
/// @author Tessera
/// @notice Protoform contract for deploying new vaults with a fixed supply, nouns style auction, and buyout mechanism
contract NounletProtoform is IProtoform, MerkleBase {
    /// @notice Address of NounletAuction module contract
    address public immutable auction;
    /// @notice Address of NounletRegistry contract
    address public immutable registry;

    /// @dev Initializes NounletRegistry and NounletAuction contracts
    constructor(address _registry, address _auction) {
        registry = _registry;
        auction = _auction;
    }

    /// @notice Deploys a new vault with given permissions and plugins
    /// @param _modules Address of the module contracts
    /// @param _plugins Addresses of plugin contracts
    /// @param _selectors List of function selectors
    /// @param _mintProof Merkle proof for minting fractions
    /// @param _descriptor Address of the NounsDescriptor contract
    /// @param _nounId ID of the NounsToken
    function deployVault(
        address[] calldata _modules,
        address[] calldata _plugins,
        bytes4[] calldata _selectors,
        bytes32[] calldata _mintProof,
        address _descriptor,
        uint256 _nounId
    ) external returns (address vault) {
        // Generates merkle tree with the list of module contracts
        bytes32[] memory leafNodes = generateMerkleTree(_modules);
        // Gets the merkle root of the leaf nodes
        bytes32 merkleRoot = getRoot(leafNodes);
        // Deploys a new vault for the NounsToken ID
        vault = IRegistry(registry).create(merkleRoot, _plugins, _selectors, _descriptor, _nounId);

        // Transfers NounsToken from caller to vault
        address nounsToken = IRegistry(registry).nounsToken();
        INouns(nounsToken).safeTransferFrom(msg.sender, vault, _nounId);
        // Creates a new auction for the NounsToken and mints the first Nounlet
        IAuction(auction).createAuction(vault, msg.sender, _mintProof);

        // Emits event with list of modules installed on the vault
        emit ActiveModules(vault, _modules);
    }

    /// @notice Generates a merkle tree from the hashed permission lists of the given modules
    /// @param _modules List of module contracts
    /// @return hashes A combined list of leaf nodes
    function generateMerkleTree(address[] calldata _modules)
        public
        view
        returns (bytes32[] memory hashes)
    {
        uint256 counter;
        uint256 hashesLength;
        for (uint256 i = 0; i < _modules.length; ++i) {
            hashesLength += IModule(_modules[i]).getLeafNodes().length;
        }
        hashes = new bytes32[](hashesLength);
        unchecked {
            for (uint256 i = 0; i < _modules.length; ++i) {
                bytes32[] memory leaves = IModule(_modules[i]).getLeafNodes();
                for (uint256 j; j < leaves.length; ++j) {
                    hashes[counter++] = leaves[j];
                }
            }
        }
    }
}