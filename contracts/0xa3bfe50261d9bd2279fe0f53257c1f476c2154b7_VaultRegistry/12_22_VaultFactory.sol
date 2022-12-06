// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Create2ClonesWithImmutableArgs} from "clones-with-immutable-args/src/Create2ClonesWithImmutableArgs.sol";
import {IVaultFactory} from "./interfaces/IVaultFactory.sol";
import {Vault, InitInfo} from "./Vault.sol";

/// @title Vault Factory
/// @author Tessera
/// @notice Factory contract for deploying Tessera vaults
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
    /// @return vault Address of deployed vault
    function deploy(bytes32 _merkleRoot) external returns (address payable vault) {
        vault = deployFor(_merkleRoot, msg.sender);
    }

    /// @notice Gets pre-computed address of vault deployed by given account
    /// @param _origin Address of vault originating account
    /// @param _owner Address of vault deployer
    /// @param _merkleRoot Merkle root of deployed vault
    /// @return vault Address of next vault
    function getNextAddress(
        address _origin,
        address _owner,
        bytes32 _merkleRoot
    ) external view returns (address vault) {
        bytes32 salt = keccak256(abi.encode(_origin, nextSeeds[_origin]));
        (uint256 creationPtr, uint256 creationSize) = implementation.cloneCreationCode(
            abi.encodePacked(_merkleRoot, _owner, address(this))
        );
        bytes32 creationHash;
        // solhint-disable-next-line no-inline-assembly
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
    /// @return vault Address of deployed vault
    function deployFor(bytes32 _merkleRoot, address _owner) public returns (address payable vault) {
        vault = _computeSalt(_merkleRoot, _owner);
    }

    /// @notice Deploys new vault for given address and executes calls
    /// @param _merkleRoot Merkle root of deployed vault
    /// @param _owner Address of vault owner
    /// @param _calls List of calls to execute upon deployment
    /// @return vault Address of deployed vault
    function deployFor(
        bytes32 _merkleRoot,
        address _owner,
        InitInfo[] calldata _calls
    ) public returns (address payable vault) {
        vault = _computeSalt(_merkleRoot, _owner);
        unchecked {
            for (uint256 i; i < _calls.length; ++i) {
                Vault(vault).execute(_calls[i].target, _calls[i].data, _calls[i].proof);
            }
        }
    }

    function _computeSalt(bytes32 _merkleRoot, address _owner)
        internal
        returns (address payable vault)
    {
        bytes32 seed = nextSeeds[tx.origin];

        // Prevent front-running the salt by hashing the concatenation of tx.origin and the user-provided seed.
        bytes32 salt = keccak256(abi.encode(tx.origin, seed));

        vault = _cloneVault(_merkleRoot, _owner, seed, salt);
    }

    function _cloneVault(
        bytes32 _merkleRoot,
        address _owner,
        bytes32 _seed,
        bytes32 _salt
    ) internal returns (address payable vault) {
        bytes memory data = abi.encodePacked(_merkleRoot, _owner, address(this));
        vault = implementation.clone(_salt, data);

        // Increment the seed.
        unchecked {
            nextSeeds[tx.origin] = bytes32(uint256(_seed) + 1);
        }

        /// Log the vault via en event.
        emit DeployVault(tx.origin, msg.sender, _owner, _seed, _salt, vault, _merkleRoot);
    }
}