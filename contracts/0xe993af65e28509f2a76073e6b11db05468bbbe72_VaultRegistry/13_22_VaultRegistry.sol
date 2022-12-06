// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ClonesWithImmutableArgs} from "clones-with-immutable-args/src/ClonesWithImmutableArgs.sol";
import {Rae} from "./Rae.sol";
import {IVault, InitInfo} from "./interfaces/IVault.sol";
import {IVaultRegistry, VaultInfo} from "./interfaces/IVaultRegistry.sol";
import {VaultFactory} from "./VaultFactory.sol";

/// @title Vault Registry
/// @author Tessera
/// @notice Registry contract for tracking all Rae vaults
contract VaultRegistry is IVaultRegistry {
    /// @dev Use clones library with address types
    using ClonesWithImmutableArgs for address;
    /// @notice Address of VaultFactory contract
    address public immutable factory;
    /// @notice Address of Rae token contract
    address public immutable rae;
    /// @notice Address of Implementation for Rae token contract
    address public immutable raeImplementation;
    /// @notice Mapping of collection address to next token ID type
    mapping(address => uint256) public nextId;
    /// @notice Mapping of vault address to vault information
    mapping(address => VaultInfo) public vaultToToken;

    /// @notice Initializes factory, implementation, and token contracts
    constructor() {
        factory = address(new VaultFactory());
        raeImplementation = address(new Rae());
        rae = raeImplementation.clone(abi.encodePacked(msg.sender, address(this)));
    }

    /// @notice Creates a new vault with permissions and initialization calls, and transfers ownership to a given owner
    /// @dev This should only be done in limited cases i.e. if you're okay with a trusted individual(s)
    /// having control over the vault. Ideally, execution would be locked behind a Multisig wallet.
    /// @param _merkleRoot Hash of merkle root for vault permissions
    /// @param _owner Address of the vault owner
    /// @param _calls List of initialization calls
    /// @return vault Address of Proxy contract
    function createFor(
        bytes32 _merkleRoot,
        address _owner,
        InitInfo[] calldata _calls
    ) public returns (address vault) {
        vault = _deployVault(_merkleRoot, _owner, rae, _calls);
    }

    /// @notice Creates a new vault with permissions
    /// @param _merkleRoot Hash of merkle root for vault permissions
    /// @return vault Address of Proxy contract
    function createFor(bytes32 _merkleRoot, address _owner) public returns (address vault) {
        vault = _deployVault(_merkleRoot, _owner, rae);
    }

    /// @notice Creates a new vault with permissions and initialization calls
    /// @param _merkleRoot Hash of merkle root for vault permissions
    /// @param _calls List of initialization calls
    /// @return vault Address of Proxy contract
    function create(bytes32 _merkleRoot, InitInfo[] calldata _calls)
        external
        returns (address vault)
    {
        vault = createFor(_merkleRoot, address(this), _calls);
    }

    /// @notice Creates a new vault with permissions and initialization calls
    /// @param _merkleRoot Hash of merkle root for vault permissions
    /// @return vault Address of Proxy contract
    function create(bytes32 _merkleRoot) external returns (address vault) {
        vault = createFor(_merkleRoot, address(this));
    }

    /// @notice Creates a new vault with permissions and initialization calls for a given controller
    /// @param _merkleRoot Hash of merkle root for vault permissions
    /// @param _controller Address of token controller
    /// @param _calls List of initialization calls
    /// @return vault Address of Proxy contract
    /// @return token Address of Rae contract
    function createCollectionFor(
        bytes32 _merkleRoot,
        address _controller,
        InitInfo[] calldata _calls
    ) public returns (address vault, address token) {
        token = raeImplementation.clone(abi.encodePacked(_controller, address(this)));
        vault = _deployVault(_merkleRoot, address(this), token, _calls);
    }

    /// @notice Creates a new vault with permissions and intialization calls for the message sender
    /// @param _merkleRoot Hash of merkle root for vault permissions
    /// @param _calls List of initialization calls
    /// @return vault Address of Proxy contract
    /// @return token Address of Rae contract
    function createCollection(bytes32 _merkleRoot, InitInfo[] calldata _calls)
        external
        returns (address vault, address token)
    {
        (vault, token) = createCollectionFor(_merkleRoot, msg.sender, _calls);
    }

    /// @notice Creates a new vault with permissions and initialization calls for an existing collection
    /// @param _merkleRoot Hash of merkle root for vault permissions
    /// @param _token Address of Rae contract
    /// @param _calls List of initialization calls
    /// @return vault Address of Proxy contract
    function createInCollection(
        bytes32 _merkleRoot,
        address _token,
        InitInfo[] calldata _calls
    ) external returns (address vault) {
        address controller = Rae(_token).controller();
        if (controller != msg.sender) revert InvalidController(controller, msg.sender);
        vault = _deployVault(_merkleRoot, address(this), _token, _calls);
    }

    /// @notice Burns vault tokens
    /// @param _from Source address
    /// @param _value Amount of tokens
    function burn(address _from, uint256 _value) external {
        VaultInfo memory info = vaultToToken[msg.sender];
        uint256 id = info.id;
        if (id == 0) revert UnregisteredVault(msg.sender);
        Rae(info.token).burn(_from, id, _value);
    }

    /// @notice Mints vault tokens
    /// @param _to Target address
    /// @param _value Amount of tokens
    function mint(address _to, uint256 _value) external {
        VaultInfo memory info = vaultToToken[msg.sender];
        uint256 id = info.id;
        if (id == 0) revert UnregisteredVault(msg.sender);
        Rae(info.token).mint(_to, id, _value, "");
    }

    /// @notice Gets the total supply for a token and ID associated with a vault
    /// @param _vault Address of the vault
    /// @return Total supply
    function totalSupply(address _vault) external view returns (uint256) {
        VaultInfo memory info = vaultToToken[_vault];
        return Rae(info.token).totalSupply(info.id);
    }

    /// @notice Gets the uri for a given token and ID associated with a vault
    /// @param _vault Address of the vault
    /// @return URI of token
    function uri(address _vault) external view returns (string memory) {
        VaultInfo memory info = vaultToToken[_vault];
        return Rae(info.token).uri(info.id);
    }

    /// @dev Deploys new vault for specified token and sets the merkle root
    /// @param _merkleRoot Hash of merkle root for vault permissions
    /// @param _token Address of Rae contract
    /// @return vault Address of Proxy contract
    function _deployVault(
        bytes32 _merkleRoot,
        address _owner,
        address _token
    ) internal returns (address vault) {
        vault = VaultFactory(factory).deployFor(_merkleRoot, _owner);
        vaultToToken[vault] = VaultInfo(_token, ++nextId[_token]);
        emit VaultDeployed(vault, _token, nextId[_token]);
    }

    /// @dev Deploys new vault for specified token and sets the merkle root
    /// @param _merkleRoot Hash of merkle root for vault permissions
    /// @param _token Address of Rae contract
    /// @param _calls List of initialization calls
    /// @return vault Address of Proxy contract
    function _deployVault(
        bytes32 _merkleRoot,
        address _owner,
        address _token,
        InitInfo[] calldata _calls
    ) internal returns (address vault) {
        // pre-compute the next vault's address in order to register it before initialization calls
        vault = VaultFactory(factory).getNextAddress(tx.origin, _owner, _merkleRoot);
        vaultToToken[vault] = VaultInfo(_token, ++nextId[_token]);
        VaultFactory(factory).deployFor(_merkleRoot, _owner, _calls);
        emit VaultDeployed(vault, _token, nextId[_token]);
    }
}