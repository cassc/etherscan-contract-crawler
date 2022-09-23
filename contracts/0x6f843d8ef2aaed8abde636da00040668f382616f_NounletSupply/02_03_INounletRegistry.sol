// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for NounletRegistry contract
interface INounletRegistry {
    /// @dev Emitted when the caller is not a registered vault
    error UnregisteredVault(address _sender);

    /// @dev Event log for deploying vault
    /// @param _vault Address of the vault
    /// @param _token Address of the token
    event VaultDeployed(address indexed _vault, address indexed _token);

    function batchBurn(address _from, uint256[] memory _ids) external;

    function create(
        bytes32 _merkleRoot,
        address[] memory _plugins,
        bytes4[] memory _selectors,
        address _descriptor,
        uint256 _nounId
    ) external returns (address vault);

    function factory() external view returns (address);

    function implementation() external view returns (address);

    function mint(address _to, uint256 _id) external;

    function nounsToken() external view returns (address);

    function royaltyBeneficiary() external view returns (address);

    function uri(address _vault, uint256 _id) external view returns (string memory);

    function vaultToToken(address) external view returns (address token);
}