// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ITransport, GasFunctionType } from '../transport/ITransport.sol';
import { VaultBaseInternal } from '../vault-base/VaultBaseInternal.sol';
import { VaultBaseExternal } from '../vault-base/VaultBaseExternal.sol';
import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';
import { Registry } from '../registry/Registry.sol';
import { RegistryStorage } from '../registry/RegistryStorage.sol';
import { VaultChildStorage } from './VaultChildStorage.sol';

import { IStargateRouter } from '@layerzerolabs/solidity-examples/contracts/interfaces/IStargateRouter.sol';

import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';

contract VaultChild is VaultBaseInternal, VaultBaseExternal {
    using SafeERC20 for IERC20;

    function initialize(
        uint16 _parentChainId,
        address _vaultParentAddress,
        address _manager,
        VaultRiskProfile _riskProfile,
        Registry _registry,
        ITransport.ChildVault[] memory _existingSiblings
    ) external {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();
        require(l.vaultId == 0, 'already initialized');

        VaultBaseInternal.initialize(_registry, _manager, _riskProfile);
        require(_parentChainId != 0, 'invalid _parentChainId');
        require(
            _vaultParentAddress != address(0),
            'invalid _vaultParentAddress'
        );

        l.vaultId = keccak256(
            abi.encodePacked(_parentChainId, _vaultParentAddress)
        );
        l.parentChainId = _parentChainId;
        l.vaultParent = _vaultParentAddress;
        for (uint8 i = 0; i < _existingSiblings.length; i++) {
            l.siblingChains.push(_existingSiblings[i].chainId);
            l.siblings[_existingSiblings[i].chainId] = _existingSiblings[i]
                .vault;
        }
    }

    ///
    /// Views
    ///

    function parentChainId() external view returns (uint16) {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();

        return l.parentChainId;
    }

    function parentVault() external view returns (address) {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();

        return l.vaultParent;
    }

    function allSiblingChainIds() external view returns (uint16[] memory) {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();
        return l.siblingChains;
    }

    function siblings(uint16 chainId) external view returns (address) {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();
        return l.siblings[chainId];
    }

    function getLzFee(
        bytes4 funcHash,
        uint16 chainId
    ) public view returns (uint fee) {
        if (funcHash == this.requestBridgeToChain.selector) {
            fee = _bridgeQuote(chainId);
        } else {
            (fee, ) = _registry().transport().getLzFee(
                GasFunctionType.standard,
                chainId
            );
        }
    }

    ///
    /// Receivers/CallBacks
    ///

    modifier bridgingApproved() {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();

        require(l.bridgeApproved, 'bridge not approved');
        _;
    }

    // called by the dstChain via lz to federate a new sibling
    function receiveAddSibling(
        uint16 siblingChainId,
        address siblingVault
    ) external onlyTransport {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();

        l.siblings[siblingChainId] = siblingVault;
        l.siblingChains.push(siblingChainId);
    }

    function receiveBridgeApproval() external onlyTransport {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();

        l.bridgeApproved = true;
        l.bridgeApprovalTime = block.timestamp;
    }

    function receiveWithdrawRequest(
        address withdrawer,
        uint portion
    ) external onlyTransport {
        _withdraw(withdrawer, portion);
    }

    function receiveManagerChange(address newManager) external onlyTransport {
        _changeManager(newManager);
    }

    ///
    /// Cross Chain Requests
    ///

    // Allows anyone to unlock the bridge lock on the parent after 5 minutes
    function requestBridgeApprovalCancellation(
        uint lzFee
    ) external payable whenNotPaused {
        require(msg.value >= lzFee, 'insufficient fee');
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();

        require(l.bridgeApproved, 'must be already approved');
        uint timeout = _registry().transport().bridgeApprovalCancellationTime();

        if (msg.sender != _manager()) {
            require(
                l.bridgeApprovalTime + timeout < block.timestamp,
                'cannot cancel yet'
            );
        }

        l.bridgeApproved = false;
        _registry().transport().sendBridgeApprovalCancellation{ value: lzFee }(
            ITransport.BridgeApprovalCancellationRequest({
                parentChainId: l.parentChainId,
                parentVault: l.vaultParent,
                requester: msg.sender
            })
        );
    }

    function requestBridgeToChain(
        uint16 dstChainId,
        address asset,
        uint amount,
        uint minAmountOut,
        uint lzFee
    ) external payable onlyManager whenNotPaused bridgingApproved {
        require(msg.value >= lzFee, 'insufficient fee');
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();

        // check minAmountOut is within threshold
        // Check siblingVault exists on chainId
        address dstVault;
        if (dstChainId == l.parentChainId) {
            dstVault = l.vaultParent;
        } else {
            dstVault = l.siblings[dstChainId];
        }

        require(dstVault != address(0), 'no dst vault');

        l.bridgeApproved = false;
        IERC20(asset).safeApprove(address(_registry().transport()), amount);
        _registry().transport().bridgeAsset{ value: lzFee }(
            dstChainId,
            dstVault,
            l.parentChainId,
            l.vaultParent,
            asset,
            amount,
            minAmountOut
        );
    }

    function _bridgeQuote(uint16 dstChainId) internal view returns (uint fee) {
        VaultChildStorage.Layout storage l = VaultChildStorage.layout();

        // check minAmountOut is within threshold
        // Check siblingVault exists on chainId
        address dstVault;
        if (dstChainId == l.parentChainId) {
            dstVault = l.vaultParent;
        } else {
            dstVault = l.siblings[dstChainId];
        }

        require(dstVault != address(0), 'no dst vault');

        fee = _registry().transport().getBridgeAssetQuote(
            dstChainId,
            dstVault,
            _registry().chainId(),
            address(this)
        );
    }
}