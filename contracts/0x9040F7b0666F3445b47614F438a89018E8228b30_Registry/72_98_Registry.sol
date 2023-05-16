// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import { Accountant } from '../Accountant.sol';
import { ITransport } from '../transport/ITransport.sol';
import { ExecutorIntegration } from '../executors/IExecutor.sol';
import { IntegrationDataTracker } from '../IntegrationDataTracker.sol';
import { RegistryStorage } from './RegistryStorage.sol';
import { GmxConfig } from '../GmxConfig.sol';
import { Transport } from '../transport/Transport.sol';
import { Constants } from '../lib/Constants.sol';
import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';
import { SafeOwnable } from '@solidstate/contracts/access/ownable/SafeOwnable.sol';

import { ILayerZeroEndpoint } from '@layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroEndpoint.sol';

import { Pausable } from '@solidstate/contracts/security/Pausable.sol';

import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';

contract Registry is SafeOwnable, Pausable {
    function initialize(
        uint16 _chainId,
        address _protocolTreasury,
        address payable _transport,
        address _parentVaultDiamond,
        address _childVaultDiamond,
        address _accountant,
        address _integrationDataTracker
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.chainId = _chainId;
        l.protocolTreasury = _protocolTreasury;
        l.transport = Transport(_transport);
        l.parentVaultDiamond = _parentVaultDiamond;
        l.childVaultDiamond = _childVaultDiamond;
        l.accountant = Accountant(_accountant);
        l.integrationDataTracker = IntegrationDataTracker(
            _integrationDataTracker
        );
        l.livelinessThreshold = 5 minutes;
        l.depositLockupTime = 24 hours;
        l.maxActiveAssets = 8;
        l.canChangeManager = false;
        l.maxCpitBips[VaultRiskProfile.low] = 300; // 3%
        l.maxCpitBips[VaultRiskProfile.medium] = 600; // 6%
        l.maxCpitBips[VaultRiskProfile.high] = 1250; // 12.5%
        l.maxSingleTradeImpactBips = 1250; // 12.5%;
        l.chainlinkTimeout = 24 hours;
        l.zeroXMaximumSingleSwapPriceImpactBasisPoints = 200; // 2%
    }

    modifier onlyTransport() {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        require(address(l.transport) == msg.sender, 'not transport');
        _;
    }

    /// VIEWS

    function maxCpitBips(
        VaultRiskProfile riskProfile
    ) external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.maxCpitBips[riskProfile];
    }

    function maxSingleTradeImpactBips() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.maxSingleTradeImpactBips;
    }

    function VAULT_PRECISION() public pure returns (uint256) {
        return Constants.VAULT_PRECISION;
    }

    function parentVaultDiamond() external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.parentVaultDiamond;
    }

    function childVaultDiamond() external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.childVaultDiamond;
    }

    function chainId() external view returns (uint16) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.chainId;
    }

    function protocolTreasury() external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.protocolTreasury;
    }

    function isVault(address vault) external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.parentVaults[vault] || l.childVaults[vault];
    }

    function isVaultParent(address vault) external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.parentVaults[vault];
    }

    function isVaultChild(address vault) external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.childVaults[vault];
    }

    function executors(
        ExecutorIntegration integration
    ) external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.executors[integration];
    }

    function redeemers(address asset) external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.redeemers[l.assetTypes[asset]];
    }

    function valuers(address asset) external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.valuers[l.assetTypes[asset]];
    }

    function deprecatedAssets(address asset) external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.deprecatedAssets[asset];
    }

    function priceAggregators(address asset) external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.priceAggregators[asset];
    }

    function maxActiveAssets() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.maxActiveAssets;
    }

    function chainlinkTimeout() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.chainlinkTimeout;
    }

    function depositLockupTime() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.depositLockupTime;
    }

    function canChangeManager() external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.canChangeManager;
    }

    function livelinessThreshold() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.livelinessThreshold;
    }

    function zeroXExchangeRouter() external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.zeroXExchangeRouter;
    }

    function zeroXMaximumSingleSwapPriceImpactBasisPoints()
        external
        view
        returns (uint256)
    {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.zeroXMaximumSingleSwapPriceImpactBasisPoints;
    }

    // Contracts

    function integrationDataTracker()
        external
        view
        returns (IntegrationDataTracker)
    {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.integrationDataTracker;
    }

    function gmxConfig() external view returns (GmxConfig) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.gmxConfig;
    }

    function accountant() external view returns (Accountant) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.accountant;
    }

    function transport() external view returns (Transport) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.transport;
    }

    /// MODIFIERS

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addVaultParent(address vault) external onlyTransport {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.parentVaults[vault] = true;
    }

    function addVaultChild(address vault) external onlyTransport {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.childVaults[vault] = true;
    }

    function setDeprecatedAsset(
        address asset,
        bool deprecated
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.deprecatedAssets[asset] = deprecated;
    }

    function setAssetType(
        address asset,
        RegistryStorage.AssetType assetType
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.assetTypes[asset] = assetType;
    }

    function setValuer(
        RegistryStorage.AssetType assetType,
        address valuer
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.valuers[assetType] = valuer;
    }

    function setRedeemer(
        RegistryStorage.AssetType assetType,
        address redeemer
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.redeemers[assetType] = redeemer;
    }

    function setPriceAggregator(
        address asset,
        address aggregator
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.priceAggregators[asset] = aggregator;
    }

    function setAccountant(address _accountant) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.accountant = Accountant(_accountant);
    }

    function setTransport(address payable _transport) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.transport = Transport(_transport);
    }

    function setProtocolTreasury(address payable _treasury) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.protocolTreasury = (_treasury);
    }

    function setIntegrationDataTracker(
        address _integrationDataTracker
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.integrationDataTracker = IntegrationDataTracker(
            _integrationDataTracker
        );
    }

    function setZeroXExchangeRouter(
        address _zeroXExchangeRouter
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.zeroXExchangeRouter = _zeroXExchangeRouter;
    }

    function setZeroXMaximumSingleSwapPriceImpactBasisPoints(
        uint256 _zeroXMaximumSingleSwapPriceImpactBasisPoints
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l
            .zeroXMaximumSingleSwapPriceImpactBasisPoints = _zeroXMaximumSingleSwapPriceImpactBasisPoints;
    }

    function setExecutor(
        ExecutorIntegration integration,
        address executor
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.executors[integration] = executor;
    }

    function setDepositLockupTime(uint _depositLockupTime) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.depositLockupTime = _depositLockupTime;
    }

    function setMaxActiveAssets(uint _maxActiveAssets) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.maxActiveAssets = _maxActiveAssets;
    }

    function setCanChangeManager(bool _canChangeManager) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.canChangeManager = _canChangeManager;
    }

    function setGmxConfig(address _gmxConfig) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.gmxConfig = GmxConfig(_gmxConfig);
    }
}