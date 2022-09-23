// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Create2ClonesWithImmutableArgs} from "clones-with-immutable-args/src/Create2ClonesWithImmutableArgs.sol";
import {IVaultFactory} from "./interfaces/IVaultFactory.sol";
import {Vault} from "./Vault.sol";

/// @title Vault Factory
/// @author Tessera
/// @notice Factory contract for deploying fractional vaults
contract VaultFactory is IVaultFactory {
    /// @dev Use clones library for address types
    using Create2ClonesWithImmutableArgs for address;
    /// @notice Address of Vault proxy contract
    address public implementation;
    /// @dev Internal mapping to track the next seed to be used by an EOA
    mapping(address => bytes32) internal nextSeeds;

    /// @notice Initializes implementation contract
    constructor() {
        implementation = address(new Vault());
    }

    /// @notice Deploys new vault for sender
    /// @param _merkleRoot Merkle root of deployed vault
    /// @param _plugins Addresses of plugin contracts
    /// @param _selectors List of function selectors
    /// @return vault Address of deployed vault
    function deploy(
        bytes32 _merkleRoot,
        address[] calldata _plugins,
        bytes4[] calldata _selectors
    ) external returns (address payable vault) {
        vault = deployFor(_merkleRoot, msg.sender, _plugins, _selectors);
    }

    /// @notice Gets pre-computed address of vault deployed by given account
    /// @param _deployer Address of vault deployer
    /// @param _merkleRoot Merkle root of deployed vault
    /// @return vault Address of next vault
    function getNextAddress(address _deployer, bytes32 _merkleRoot)
        external
        view
        returns (address vault)
    {
        bytes32 salt = keccak256(abi.encode(_deployer, nextSeeds[_deployer]));
        (uint256 creationPtr, uint256 creationSize) = implementation.cloneCreationCode(
            abi.encodePacked(_merkleRoot, _deployer, address(this))
        );

        bytes32 creationHash;
        assembly {
            creationHash := keccak256(creationPtr, creationSize)
        }
        bytes32 data = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, creationHash));
        vault = address(uint160(uint256(data)));
    }

    /// @notice Gets next seed value of given account
    /// @param _deployer Address of vault deployer
    /// @return Value of next seed
    function getNextSeed(address _deployer) external view returns (bytes32) {
        return nextSeeds[_deployer];
    }

    /// @notice Deploys new vault for given address
    /// @param _merkleRoot Merkle root of deployed vault
    /// @param _owner Address of vault owner
    /// @param _plugins Addresses of plugin contracts
    /// @param _selectors List of function selectors
    /// @return vault Address of deployed vault
    function deployFor(
        bytes32 _merkleRoot,
        address _owner,
        address[] calldata _plugins,
        bytes4[] calldata _selectors
    ) public returns (address payable vault) {
        bytes32 seed = nextSeeds[tx.origin];

        // Prevent front-running the salt by hashing the concatenation of tx.origin and the user-provided seed.
        bytes32 salt = keccak256(abi.encode(tx.origin, seed));

        bytes memory data = abi.encodePacked(_merkleRoot, _owner, address(this));
        vault = implementation.clone(salt, data);

        // Increment the seed.
        unchecked {
            nextSeeds[tx.origin] = bytes32(uint256(seed) + 1);
        }

        Vault(vault).setPlugins(_plugins, _selectors);

        // Log the vault via en event.
        emit DeployVault(tx.origin, msg.sender, _owner, seed, salt, vault);
    }
}