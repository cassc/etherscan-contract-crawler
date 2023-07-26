// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Registry } from '../registry/Registry.sol';
import { Constants } from '../lib/Constants.sol';
import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';
import { IGmxPositionRouterCallbackReceiver } from '../interfaces/IGmxPositionRouterCallbackReceiver.sol';
import { ExecutorIntegration } from '../executors/IExecutor.sol';
import { IRedeemer } from '../redeemers/IRedeemer.sol';
import { Call } from '../lib/Call.sol';
import { VaultBaseStorage } from './VaultBaseStorage.sol';
import { CPIT } from '../cpit/CPIT.sol';

import { ReentrancyGuard } from '@solidstate/contracts/utils/ReentrancyGuard.sol';
import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';

contract VaultBaseInternal is ReentrancyGuard, CPIT {
    using SafeERC20 for IERC20;

    event Withdraw(
        uint tokenId,
        address withdrawer,
        uint portion,
        address[] assets
    );
    event AssetAdded(address asset);
    event AssetRemoved(address asset);
    event BridgeReceived(address asset);
    event BridgeSent(
        uint16 dstChainId,
        address dstVault,
        address asset,
        uint amount
    );

    modifier whenNotPaused() {
        require(!_registry().paused(), 'paused');
        _;
    }

    modifier onlyTransport() {
        require(
            address(_registry().transport()) == msg.sender,
            'not transport'
        );
        _;
    }

    modifier onlyThis() {
        require(address(this) == msg.sender, 'not this');
        _;
    }

    modifier onlyManager() {
        require(_manager() == msg.sender, 'not manager');
        _;
    }

    function initialize(
        Registry registry,
        address manager,
        VaultRiskProfile riskProfile
    ) internal {
        require(manager != address(0), 'invalid _manager');
        require(address(registry) != address(0), 'invalid _registry');

        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        l.registry = Registry(registry);
        l.manager = manager;
        l.riskProfile = riskProfile;
    }

    function _updateActiveAsset(address asset) internal {
        if (_hasValue(asset)) {
            _addAsset(asset);
        } else {
            _removeAsset(asset);
        }
    }

    function _receiveBridgedAsset(address asset) internal {
        _updateActiveAsset(asset);
        emit BridgeReceived(asset);
        _registry().emitEvent();
    }

    // The Executor runs as the Vault. I'm not sure this is ideal but it makes writing executors easy
    // Other solutions are
    // 1. The executor returns transactions to be executed which are then assembly called by the this
    // 2. We write the executor code in the vault
    function _execute(
        ExecutorIntegration integration,
        bytes memory encodedWithSelectorPayload
    ) internal isNotCPITLocked {
        // Get value before for CPIT
        (, uint valueBefore) = _getVaultValue();

        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        address executor = l.registry.executors(integration);
        require(executor != address(0), 'no executor');
        // Make the external call
        Call._delegate(executor, encodedWithSelectorPayload);

        // Get value after for CPIT
        (, uint valueAfter) = _getVaultValue();
        uint txPriceImpact = _updatePriceImpact(
            valueBefore,
            valueAfter,
            _registry().maxCpitBips(l.riskProfile)
        );
        require(
            txPriceImpact < _registry().maxSingleActionImpactBips(),
            'Max price impact exceeded'
        );
    }

    // The Redeemer runs as the Vault. I'm not sure this is ideal but it makes writing Redeemers easy
    // Other solutions are
    // 1. The Redeemer returns transactions to be executed which are then assembly called by the this
    // 2. We write the Redeemer code in the vault
    function _withdraw(
        uint tokenId,
        address withdrawer,
        uint portion
    ) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();

        for (uint i = 0; i < l.assets.length; i++) {
            address redeemer = l.registry.redeemers(l.assets[i]);
            require(redeemer != address(0), 'no redeemer');
            if (IRedeemer(redeemer).hasPreWithdraw()) {
                Call._delegate(
                    redeemer,
                    abi.encodeWithSelector(
                        IRedeemer.preWithdraw.selector,
                        tokenId,
                        l.assets[i],
                        withdrawer,
                        portion
                    )
                );
            }
        }

        // We need to take a memory refence as we remove assets that are fully withdrawn
        // And this means that the assets array will change length
        // This should not be moved before preWithdraw because preWithdraw can add active assets
        address[] memory assets = l.assets;

        for (uint i = 0; i < assets.length; i++) {
            address redeemer = l.registry.redeemers(assets[i]);
            Call._delegate(
                redeemer,
                abi.encodeWithSelector(
                    IRedeemer.withdraw.selector,
                    tokenId,
                    assets[i],
                    withdrawer,
                    portion
                )
            );
            // In some cases such as gmx the position will be closed down and we should stop tracking
            // In the case of the withdrawer owns 100% of the vault
            _updateActiveAsset(assets[i]);
        }

        emit Withdraw(tokenId, withdrawer, portion, assets);
        _registry().emitEvent();
    }

    function _bridgeAsset(
        uint16 dstChainId,
        address dstVault,
        uint16 parentChainId,
        address vaultParent,
        address asset,
        uint amount,
        uint minAmountOut,
        uint lzFee
    ) internal {
        // The max slippage the stargate ui shows is 1%
        // check minAmountOut is within this threshold
        uint internalMinAmountOut = (amount * 99) / 100;
        require(minAmountOut >= internalMinAmountOut, 'minAmountOut too low');

        IERC20(asset).safeApprove(address(_registry().transport()), amount);
        _registry().transport().bridgeAsset{ value: lzFee }(
            dstChainId,
            dstVault,
            parentChainId,
            vaultParent,
            asset,
            amount,
            minAmountOut
        );
        emit BridgeSent(dstChainId, dstVault, asset, amount);
        _registry().emitEvent();
        _updateActiveAsset(asset);
    }

    function _gmxPositionCallback(
        bytes32 positionKey,
        bool isExecuted,
        bool isIncrease
    ) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        require(
            msg.sender == address(l.registry.gmxConfig().positionRouter()),
            'not gmx'
        );
        address executor = l.registry.executors(ExecutorIntegration.GMX);
        require(executor != address(0), 'no executor');
        Call._delegate(
            executor,
            abi.encodeWithSelector(
                IGmxPositionRouterCallbackReceiver.gmxPositionCallback.selector,
                positionKey,
                isExecuted,
                isIncrease
            )
        );
    }

    function _removeAsset(address asset) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        if (l.enabledAssets[asset]) {
            for (uint i = 0; i < l.assets.length; i++) {
                if (l.assets[i] == asset) {
                    _removeFromArray(l.assets, i);
                    l.enabledAssets[asset] = false;

                    emit AssetRemoved(asset);
                    _registry().emitEvent();
                }
            }
        }
    }

    function _addAsset(address asset) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        require(
            l.registry.accountant().isSupportedAsset(asset),
            'asset not supported'
        );
        if (!l.enabledAssets[asset]) {
            l.enabledAssets[asset] = true;
            l.assets.push(asset);
            require(
                l.assets.length <= l.registry.maxActiveAssets(),
                'too many assets'
            );

            emit AssetAdded(asset);
            _registry().emitEvent();
        }
    }

    function _removeFromArray(address[] storage array, uint index) internal {
        require(index < array.length);
        array[index] = array[array.length - 1];
        array.pop();
    }

    function _changeManager(address newManager) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        l.manager = newManager;
    }

    function _setVaultId(bytes32 vaultId) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        l.vaultId = vaultId;
    }

    function _registry() internal view returns (Registry) {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        return l.registry;
    }

    function _riskProfile() internal view returns (VaultRiskProfile) {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        return l.riskProfile;
    }

    function _manager() internal view returns (address) {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        return l.manager;
    }

    function _vaultId() internal view returns (bytes32) {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        return l.vaultId;
    }

    function _getVaultValue()
        internal
        view
        returns (uint minValue, uint maxValue)
    {
        return _registry().accountant().getVaultValue(address(this));
    }

    function _hasValue(address asset) internal view returns (bool) {
        (, uint maxValue) = _registry().accountant().assetValueOfVault(
            asset,
            address(this)
        );
        return maxValue > 0;
    }
}