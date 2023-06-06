// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IVaultFactory {
    event WithdrawVaultCreated(address withdrawVault);
    event NodeELRewardVaultCreated(address nodeDistributor);
    event UpdatedStaderConfig(address staderConfig);
    event UpdatedVaultProxyImplementation(address vaultProxyImplementation);

    function NODE_REGISTRY_CONTRACT() external view returns (bytes32);

    function deployWithdrawVault(
        uint8 _poolId,
        uint256 _operatorId,
        uint256 _validatorCount,
        uint256 _validatorId
    ) external returns (address);

    function deployNodeELRewardVault(uint8 _poolId, uint256 _operatorId) external returns (address);

    function computeWithdrawVaultAddress(
        uint8 _poolId,
        uint256 _operatorId,
        uint256 _validatorCount
    ) external view returns (address);

    function computeNodeELRewardVaultAddress(uint8 _poolId, uint256 _operatorId) external view returns (address);

    function getValidatorWithdrawCredential(address _withdrawVault) external pure returns (bytes memory);

    function updateStaderConfig(address _staderConfig) external;

    function updateVaultProxyAddress(address _vaultProxyImpl) external;
}