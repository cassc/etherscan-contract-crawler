// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { Registry } from '../registry/Registry.sol';
import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';
import { IGmxPositionRouterCallbackReceiver } from '../interfaces/IGmxPositionRouterCallbackReceiver.sol';
import { ExecutorIntegration } from '../executors/IExecutor.sol';
import { IRedeemer } from '../redeemers/IRedeemer.sol';
import { Call } from '../lib/Call.sol';
import { VaultBaseStorage } from './VaultBaseStorage.sol';
import { CPIT } from '../cpit/CPIT.sol';

import { ReentrancyGuard } from '@solidstate/contracts/utils/ReentrancyGuard.sol';

contract VaultBaseInternal is ReentrancyGuard, CPIT {
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

    function _getVaultValue() internal view returns (uint value) {
        value = _registry().accountant().getVaultValue(address(this));
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
        uint valueBefore = _getVaultValue();

        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        address executor = l.registry.executors(integration);
        require(executor != address(0), 'no executor');
        // Make the external call
        Call._delegate(executor, encodedWithSelectorPayload);

        // Get value after for CPIT
        uint valueAfter = _getVaultValue();
        uint txPriceImpact = _updatePriceImpact(
            valueBefore,
            valueAfter,
            _registry().maxCpitBips(l.riskProfile)
        );
        require(
            txPriceImpact < _registry().maxSingleTradeImpactBips(),
            'Max price impact exceeded'
        );
    }

    // The Redeemer runs as the Vault. I'm not sure this is ideal but it makes writing Redeemers easy
    // Other solutions are
    // 1. The Redeemer returns transactions to be executed which are then assembly called by the this
    // 2. We write the Redeemer code in the vault
    function _withdraw(address withdrawer, uint portion) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        for (uint i = 0; i < l.assets.length; i++) {
            address redeemer = l.registry.redeemers(l.assets[i]);
            require(redeemer != address(0), 'no redeemer');
            if (IRedeemer(redeemer).hasPreWithdraw()) {
                Call._delegate(
                    redeemer,
                    abi.encodeWithSelector(
                        IRedeemer.preWithdraw.selector,
                        l.assets[i],
                        withdrawer,
                        portion
                    )
                );
            }
        }
        for (uint i = 0; i < l.assets.length; i++) {
            address redeemer = l.registry.redeemers(l.assets[i]);
            Call._delegate(
                redeemer,
                abi.encodeWithSelector(
                    IRedeemer.withdraw.selector,
                    l.assets[i],
                    withdrawer,
                    portion
                )
            );
        }
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

    function _hasValue(address asset) internal view returns (bool) {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        return
            l.registry.accountant().assetValueOfVault(asset, address(this)) > 0;
    }

    function _updateActiveAsset(address asset) internal {
        if (_hasValue(asset)) {
            _addAsset(asset);
        } else {
            _removeAsset(asset);
        }
    }

    function _removeAsset(address asset) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        if (l.enabledAssets[asset]) {
            for (uint i = 0; i < l.assets.length; i++) {
                if (l.assets[i] == asset) {
                    _remove(l.assets, i);
                    l.enabledAssets[asset] = false;
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
        }
    }

    function _remove(address[] storage array, uint index) internal {
        require(index < array.length);
        array[index] = array[array.length - 1];
        array.pop();
    }

    function _changeManager(address newManager) internal {
        VaultBaseStorage.Layout storage l = VaultBaseStorage.layout();
        l.manager = newManager;
    }
}