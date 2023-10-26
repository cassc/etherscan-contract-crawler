// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ITransport } from '../transport/ITransport.sol';
import { VaultParentInternal } from '../vault-parent/VaultParentInternal.sol';
import { VaultParentStorage } from './VaultParentStorage.sol';

contract VaultParentTransport is VaultParentInternal {
    event ReceivedChildValue();
    event ReceivedWithdrawComplete(uint withdrawsStillInProgress);
    event ReceivedChildCreated(uint16 childChainId, address childVault);

    ///
    /// Receivers/CallBacks
    ///

    function receiveWithdrawComplete() external onlyTransport {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        l.withdrawsInProgress--;
        _registry().emitEvent();
        emit ReceivedWithdrawComplete(l.withdrawsInProgress);
    }

    // Callback for once the sibling has been created on the dstChain
    function receiveChildCreated(
        uint16 childChainId,
        address childVault
    ) external onlyTransport {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        if (l.children[childChainId] == address(0)) {
            l.childCreationInProgress = false;
            l.childIsInactive[childChainId] = true;
            for (uint8 i = 0; i < l.childChains.length; i++) {
                // Federate the new sibling to the other children
                _registry().transport().sendAddSiblingRequest(
                    ITransport.AddVaultSiblingRequest({
                        // The existing child
                        child: ITransport.ChildVault({
                            vault: l.children[l.childChains[i]],
                            chainId: l.childChains[i]
                        }),
                        // The new Sibling
                        newSibling: ITransport.ChildVault({
                            vault: childVault,
                            chainId: childChainId
                        })
                    })
                );
            }
            // It's important these are here and not before the for loop
            // We only want to iterate over the existing children
            l.children[childChainId] = childVault;
            l.childChains.push(childChainId);

            _registry().emitEvent();
            emit ReceivedChildCreated(childChainId, childVault);
        }
    }

    // Callback to notify the parent the bridge has taken place
    function receiveBridgedAssetAcknowledgement(
        uint16 receivingChainId
    ) external onlyTransport {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();
        // While a bridge is underway everything is locked (deposits/withdraws etc)
        // Once the bridge is complete we need to clear the stale values we have for the childVaults
        // If a requestTotalSync completes (which is valid for 10 mins),
        // then a bridge takes place from a child to the parent and completes within 10 mins,
        // then the parent will have stale values for the childVaults but the extra value from the bridge
        // This enforces that a requestTotalSync must happen after a bridge completes.
        for (uint8 i = 0; i < l.childChains.length; i++) {
            l.chainTotalValues[l.childChains[i]].lastUpdate = 0;
        }
        // Update the childChain to be active
        l.childIsInactive[receivingChainId] = false;
        l.bridgeInProgress = false;
        l.bridgeApprovedFor = 0;
    }

    // Allows the bridge approval to be cancelled by the receiver
    // after a period of time if the bridge doesn't take place
    function receiveBridgeApprovalCancellation(
        address requester
    ) external onlyTransport {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        l.bridgeInProgress = false;
        l.bridgeApprovedFor = 0;
        if (requester != _manager()) {
            l.lastBridgeCancellation = block.timestamp;
        }
    }

    // Callback to receive value/supply updates
    function receiveChildValue(
        uint16 childChainId,
        uint minValue,
        uint maxValue,
        uint time
    ) external onlyTransport {
        // We don't accept value updates while WithdrawInProgress
        // As the value could be stale (from before the withdraw is executed)
        // We also don't allow requestTotalValueUpdateMultiChain to be called
        // until all withdraw processing on all chains is complete.
        // We adjust the min and maxValues proportionally after each withdraw
        if (!_withdrawInProgress()) {
            VaultParentStorage.Layout storage l = VaultParentStorage.layout();

            l.chainTotalValues[childChainId] = VaultParentStorage.ChainValue({
                minValue: minValue,
                maxValue: maxValue,
                lastUpdate: time
            });

            _registry().emitEvent();
            emit ReceivedChildValue();
        }
    }
}