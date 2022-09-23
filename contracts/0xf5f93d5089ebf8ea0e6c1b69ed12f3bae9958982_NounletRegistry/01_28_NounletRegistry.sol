// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ClonesWithImmutableArgs} from "clones-with-immutable-args/src/ClonesWithImmutableArgs.sol";
import {NounletToken} from "./NounletToken.sol";
import {VaultFactory} from "./VaultFactory.sol";

import {INounletRegistry as IRegistry} from "./interfaces/INounletRegistry.sol";
import {IVault} from "./interfaces/IVault.sol";

/// @title NounletRegistry
/// @author Tessera
/// @notice Registry contract for tracking all fractionalized NounsToken vaults
contract NounletRegistry is IRegistry {
    /// @dev Using clones library with address types
    using ClonesWithImmutableArgs for address;
    /// @notice Address of VaultFactory contract
    address public immutable factory;
    /// @notice Address of Implementation for NounletToken contract
    address public immutable implementation;
    /// @notice Address of NounsToken contract
    address public immutable nounsToken;
    /// @notice Address of token royalty beneficiary
    address public immutable royaltyBeneficiary;
    /// @notice Mapping of vault address to token address
    mapping(address => address) public vaultToToken;

    /// @dev Initializes factory, implementation, and token contracts
    constructor(address _royaltyBeneficiary, address _nounsToken) {
        factory = address(new VaultFactory());
        implementation = address(new NounletToken());
        royaltyBeneficiary = _royaltyBeneficiary;
        nounsToken = _nounsToken;
    }

    /// @notice Burns vault tokens for multiple IDs
    /// @param _from Address to burn fraction tokens from
    /// @param _ids Token IDs to burn
    function batchBurn(address _from, uint256[] memory _ids) external {
        address info = vaultToToken[msg.sender];
        if (info == address(0)) revert UnregisteredVault(msg.sender);
        NounletToken(info).batchBurn(_from, _ids);
    }

    /// @notice Creates a new vault with permissions and plugins
    /// @param _merkleRoot Hash of merkle root for vault permissions
    /// @param _plugins Addresses of plugin contracts
    /// @param _selectors List of function selectors
    /// @return vault Address of Proxy contract
    function create(
        bytes32 _merkleRoot,
        address[] memory _plugins,
        bytes4[] memory _selectors,
        address _descriptor,
        uint256 _nounId
    ) external returns (address vault) {
        address token = implementation.clone(
            abi.encodePacked(address(this), _descriptor, _nounId, royaltyBeneficiary, nounsToken)
        );
        vault = _deployVault(_merkleRoot, token, _plugins, _selectors);
    }

    /// @notice Mints vault token
    /// @param _to Target address
    /// @param _id ID of token
    function mint(address _to, uint256 _id) external {
        address info = vaultToToken[msg.sender];
        if (info == address(0)) revert UnregisteredVault(msg.sender);
        NounletToken(info).mint(_to, _id, "");
    }

    /// @notice Gets the uri for a given token and ID associated with a vault
    /// @param _vault Address of the vault
    /// @param _id ID of the token
    /// @return URI of token
    function uri(address _vault, uint256 _id) external view returns (string memory) {
        address info = vaultToToken[_vault];
        return NounletToken(info).uri(_id);
    }

    /// @dev Deploys new vault for specified token, sets merkle root, and installs plugins
    /// @param _merkleRoot Hash of merkle root for vault permissions
    /// @param _token Address of FERC1155 contract
    /// @param _plugins Addresses of plugin contracts
    /// @param _selectors List of function selectors
    /// @return vault Address of Proxy contract
    function _deployVault(
        bytes32 _merkleRoot,
        address _token,
        address[] memory _plugins,
        bytes4[] memory _selectors
    ) private returns (address vault) {
        vault = VaultFactory(factory).deploy(_merkleRoot, _plugins, _selectors);
        vaultToToken[vault] = _token;
        emit VaultDeployed(vault, _token);
    }
}