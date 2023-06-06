// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import '../library/UtilLib.sol';
import '../VaultProxy.sol';
import '../interfaces/IVaultFactory.sol';
import '../interfaces/IStaderConfig.sol';

import '@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

contract VaultFactory is IVaultFactory, AccessControlUpgradeable {
    IStaderConfig public staderConfig;
    address public vaultProxyImplementation;

    bytes32 public constant override NODE_REGISTRY_CONTRACT = keccak256('NODE_REGISTRY_CONTRACT');

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _admin, address _staderConfig) external initializer {
        UtilLib.checkNonZeroAddress(_admin);
        UtilLib.checkNonZeroAddress(_staderConfig);
        __AccessControl_init_unchained();

        staderConfig = IStaderConfig(_staderConfig);
        vaultProxyImplementation = address(new VaultProxy());

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function deployWithdrawVault(
        uint8 _poolId,
        uint256 _operatorId,
        uint256 _validatorCount,
        uint256 _validatorId
    ) external override onlyRole(NODE_REGISTRY_CONTRACT) returns (address) {
        bytes32 salt = sha256(abi.encode(_poolId, _operatorId, _validatorCount));
        address withdrawVaultAddress = ClonesUpgradeable.cloneDeterministic(vaultProxyImplementation, salt);
        VaultProxy(payable(withdrawVaultAddress)).initialise(true, _poolId, _validatorId, address(staderConfig));

        emit WithdrawVaultCreated(withdrawVaultAddress);
        return withdrawVaultAddress;
    }

    function deployNodeELRewardVault(uint8 _poolId, uint256 _operatorId)
        external
        override
        onlyRole(NODE_REGISTRY_CONTRACT)
        returns (address)
    {
        bytes32 salt = sha256(abi.encode(_poolId, _operatorId));
        address nodeELRewardVaultAddress = ClonesUpgradeable.cloneDeterministic(vaultProxyImplementation, salt);
        VaultProxy(payable(nodeELRewardVaultAddress)).initialise(false, _poolId, _operatorId, address(staderConfig));

        emit NodeELRewardVaultCreated(nodeELRewardVaultAddress);
        return nodeELRewardVaultAddress;
    }

    function computeWithdrawVaultAddress(
        uint8 _poolId,
        uint256 _operatorId,
        uint256 _validatorCount
    ) external view override returns (address) {
        bytes32 salt = sha256(abi.encode(_poolId, _operatorId, _validatorCount));
        return ClonesUpgradeable.predictDeterministicAddress(vaultProxyImplementation, salt);
    }

    function computeNodeELRewardVaultAddress(uint8 _poolId, uint256 _operatorId)
        external
        view
        override
        returns (address)
    {
        bytes32 salt = sha256(abi.encode(_poolId, _operatorId));
        return ClonesUpgradeable.predictDeterministicAddress(vaultProxyImplementation, salt);
    }

    function getValidatorWithdrawCredential(address _withdrawVault) external pure override returns (bytes memory) {
        return abi.encodePacked(bytes1(0x01), bytes11(0x0), address(_withdrawVault));
    }

    //update the address of staderConfig
    function updateStaderConfig(address _staderConfig) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        UtilLib.checkNonZeroAddress(_staderConfig);
        staderConfig = IStaderConfig(_staderConfig);
        emit UpdatedStaderConfig(_staderConfig);
    }

    //update the implementation address of vaultProxy contract
    function updateVaultProxyAddress(address _vaultProxyImpl) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        UtilLib.checkNonZeroAddress(_vaultProxyImpl);
        vaultProxyImplementation = _vaultProxyImpl;
        emit UpdatedVaultProxyImplementation(vaultProxyImplementation);
    }
}