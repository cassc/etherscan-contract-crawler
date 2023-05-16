// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ITransport } from '../transport/ITransport.sol';
import { VaultBaseInternal } from '../vault-base/VaultBaseInternal.sol';
import { VaultParentStorage } from './VaultParentStorage.sol';

contract VaultParentTransport is VaultBaseInternal {
    ///
    /// Receivers/CallBacks
    ///

    function receiveWithdrawComplete() external onlyTransport {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        l.withdrawsInProgress--;
    }

    // Callback for once the sibling has been created on the dstChain
    function receiveChildCreated(
        uint16 childChainId,
        address childVault
    ) external onlyTransport {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        if (l.children[childChainId] == address(0)) {
            l.childCreationInProgress = false;
            for (uint8 i = 0; i < l.childChains.length; i++) {
                // Federate the new sibling to the other children
                _registry().transport().sendAddSiblingRequest(
                    ITransport.AddVaultChildRequest({
                        vault: l.children[l.childChains[i]],
                        chainId: l.childChains[i],
                        // The new Sibling
                        newChild: ITransport.ChildVault({
                            vault: childVault,
                            chainId: childChainId
                        })
                    })
                );
            }

            l.children[childChainId] = childVault;
            l.childChains.push(childChainId);
        }
    }

    // Callback to notify the parent the bridge has taken place
    function receiveBridgedAssetAcknowledgement() external onlyTransport {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        l.bridgeInProgress = false;
    }

    // Allows the bridge approval to be cancelled by the receiver after a period of time if the bridge doesn't take place
    function receiveBridgeApprovalCancellation(
        address requester
    ) external onlyTransport {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        l.bridgeInProgress = false;
        if (requester != _manager()) {
            l.lastBridgeCancellation = block.timestamp;
        }
    }

    // Callback to receive value/supply updates
    function receiveChildValue(
        uint16 childChainId,
        uint value,
        uint time
    ) external onlyTransport {
        VaultParentStorage.Layout storage l = VaultParentStorage.layout();

        l.chainTotalValues[childChainId] = VaultParentStorage.ChainValue({
            value: value,
            lastUpdate: time
        });
    }
}