// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import { Accountant } from '../Accountant.sol';
import { ITransport } from '../transport/ITransport.sol';
import { ExecutorIntegration } from '../executors/IExecutor.sol';
import { IntegrationDataTracker } from '../integration-data-tracker/IntegrationDataTracker.sol';
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
    // Emit event that informs that the other event was emitted on the target address
    event EventEmitted(address target);

    event AssetTypeChanged(address asset, RegistryStorage.AssetType assetType);
    event AssetDeprecationChanged(address asset, bool deprecated);

    modifier onlyTransport() {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        require(address(l.transport) == msg.sender, 'not transport');
        _;
    }

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
        require(l.chainId == 0, 'Already initialized');
        l.chainId = _chainId;
        l.protocolTreasury = _protocolTreasury;
        l.transport = Transport(_transport);
        l.parentVaultDiamond = _parentVaultDiamond;
        l.childVaultDiamond = _childVaultDiamond;
        l.accountant = Accountant(_accountant);
        l.integrationDataTracker = IntegrationDataTracker(
            _integrationDataTracker
        );
        l.chainlinkTimeout = 24 hours;
    }

    /// MODIFIERS

    function emitEvent() external {
        _emitEvent(msg.sender);
    }

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
        emit AssetDeprecationChanged(asset, deprecated);
        _emitEvent(address(this));
    }

    function setAssetType(
        address asset,
        RegistryStorage.AssetType assetType
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.assetTypes[asset] = assetType;
        emit AssetTypeChanged(asset, assetType);
        _emitEvent(address(this));
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

    function setZeroXMaximumSingleSwapPriceImpactBips(
        uint256 _zeroXMaximumSingleSwapPriceImpactBips
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l
            .zeroXMaximumSingleSwapPriceImpactBips = _zeroXMaximumSingleSwapPriceImpactBips;
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

    function setLivelinessThreshold(
        uint256 _livelinessThreshold
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.livelinessThreshold = _livelinessThreshold;
    }

    function setMaxCpitBips(
        VaultRiskProfile riskProfile,
        uint256 _maxCpitBips
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.maxCpitBips[riskProfile] = _maxCpitBips;
    }

    function setMinDepositAmount(uint256 _minDepositAmount) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.minDepositAmount = _minDepositAmount;
    }

    function setCanChangeManagerFees(
        bool _canChangeManagerFees
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.canChangeManagerFees = _canChangeManagerFees;
    }

    function setMaxSingleActionImpactBips(
        uint256 _maxSingleActionImpactBips
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.maxSingleActionImpactBips = _maxSingleActionImpactBips;
    }

    function setDepositAsset(
        address _depositAsset,
        bool canDeposit
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.depositAssets[_depositAsset] = canDeposit;
    }

    function setVaultValueCap(uint256 _vaultValueCap) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.vaultValueCap = _vaultValueCap;
    }

    function addRemoveAllowedInvestors(
        address[] memory allowed,
        address[] memory notAllowed
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        for (uint256 i = 0; i < allowed.length; i++) {
            l.allowedInvestors[allowed[i]] = true;
        }
        for (uint256 i = 0; i < notAllowed.length; i++) {
            l.allowedInvestors[notAllowed[i]] = false;
        }
    }

    function setInvestorWhitelistEnabled(bool enabled) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.investorWhitelistEnabled = enabled;
    }

    function addRemoveAllowedManagers(
        address[] memory allowed,
        address[] memory notAllowed
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        for (uint256 i = 0; i < allowed.length; i++) {
            l.allowedManagers[allowed[i]] = true;
        }
        for (uint256 i = 0; i < notAllowed.length; i++) {
            l.allowedManagers[notAllowed[i]] = false;
        }
    }

    function setManagerWhitelistEnabled(bool enabled) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.managerWhitelistEnabled = enabled;
    }

    function setWithdrawAutomator(
        address _withdrawAutomator
    ) external onlyOwner {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        l.withdrawAutomator = _withdrawAutomator;
    }

    /// VIEWS

    function withdrawAutomator() external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.withdrawAutomator;
    }

    function allowedInvestors(address investor) external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        if (l.investorWhitelistEnabled == true) {
            return l.allowedInvestors[investor];
        }
        return true;
    }

    function allowedManagers(address manager) external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        if (l.managerWhitelistEnabled == true) {
            return l.allowedManagers[manager];
        }
        return true;
    }

    function vaultValueCap() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.vaultValueCap;
    }

    function maxCpitBips(
        VaultRiskProfile riskProfile
    ) external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.maxCpitBips[riskProfile];
    }

    function maxSingleActionImpactBips() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.maxSingleActionImpactBips;
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

    function depositAssets(address asset) external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.depositAssets[asset];
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

    function minDepositAmount() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.minDepositAmount;
    }

    function canChangeManager() external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.canChangeManager;
    }

    function canChangeManagerFees() external view returns (bool) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.canChangeManagerFees;
    }

    function livelinessThreshold() external view returns (uint256) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.livelinessThreshold;
    }

    function zeroXExchangeRouter() external view returns (address) {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.zeroXExchangeRouter;
    }

    function zeroXMaximumSingleSwapPriceImpactBips()
        external
        view
        returns (uint256)
    {
        RegistryStorage.Layout storage l = RegistryStorage.layout();
        return l.zeroXMaximumSingleSwapPriceImpactBips;
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

    function VAULT_PRECISION() external pure returns (uint256) {
        return Constants.VAULT_PRECISION;
    }

    function _emitEvent(address caller) internal {
        emit EventEmitted(caller);
    }
}