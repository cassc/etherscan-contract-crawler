// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IStargateRouter } from '@layerzerolabs/solidity-examples/contracts/interfaces/IStargateRouter.sol';
import { VaultRiskProfile } from '../vault-base/IVaultRiskProfile.sol';

enum GasFunctionType {
    standardNoReturnMessage,
    createChildRequiresReturnMessage,
    getVaultValueRequiresReturnMessage,
    withdrawRequiresReturnMessage,
    sgReceiveRequiresReturnMessage
}

interface ITransport {
    struct SGReceivePayload {
        address dstVault;
        address srcVault;
        uint16 parentChainId;
        address parentVault;
    }

    struct SGBridgedAssetReceivedAcknoledgementRequest {
        uint16 parentChainId;
        address parentVault;
    }

    struct ChildVault {
        uint16 chainId;
        address vault;
    }

    struct VaultChildCreationRequest {
        address parentVault;
        uint16 parentChainId;
        uint16 newChainId;
        address manager;
        VaultRiskProfile riskProfile;
        ChildVault[] children;
    }

    struct ChildCreatedRequest {
        address parentVault;
        uint16 parentChainId;
        ChildVault newChild;
    }

    struct AddVaultSiblingRequest {
        ChildVault child;
        ChildVault newSibling;
    }

    struct BridgeApprovalRequest {
        uint16 approvedChainId;
        address approvedVault;
    }

    struct BridgeApprovalCancellationRequest {
        uint16 parentChainId;
        address parentVault;
        address requester;
    }

    struct ValueUpdateRequest {
        uint16 parentChainId;
        address parentVault;
        ChildVault child;
    }

    struct ValueUpdatedRequest {
        uint16 parentChainId;
        address parentVault;
        ChildVault child;
        uint time;
        uint minValue;
        uint maxValue;
    }

    struct WithdrawRequest {
        uint16 parentChainId;
        address parentVault;
        ChildVault child;
        uint tokenId;
        address withdrawer;
        uint portion;
    }

    struct WithdrawComplete {
        uint16 parentChainId;
        address parentVault;
    }

    struct ChangeManagerRequest {
        ChildVault child;
        address newManager;
    }

    receive() external payable;

    function addSibling(AddVaultSiblingRequest memory request) external;

    function bridgeApproval(BridgeApprovalRequest memory request) external;

    function bridgeApprovalCancellation(
        BridgeApprovalCancellationRequest memory request
    ) external;

    function bridgeAsset(
        uint16 dstChainId,
        address dstVault,
        uint16 parentChainId,
        address parentVault,
        address bridgeToken,
        uint256 amount,
        uint256 minAmountOut
    ) external payable;

    function childCreated(ChildCreatedRequest memory request) external;

    function createVaultChild(
        VaultChildCreationRequest memory request
    ) external;

    function createParentVault(
        string memory name,
        string memory symbol,
        address manager,
        uint streamingFee,
        uint performanceFee,
        VaultRiskProfile riskProfile
    ) external returns (address deployment);

    function getVaultValue(ValueUpdateRequest memory request) external;

    function sendChangeManagerRequest(
        ChangeManagerRequest memory request
    ) external payable;

    function sendAddSiblingRequest(
        AddVaultSiblingRequest memory request
    ) external;

    function sendBridgeApproval(
        BridgeApprovalRequest memory request
    ) external payable;

    function sendBridgeApprovalCancellation(
        BridgeApprovalCancellationRequest memory request
    ) external payable;

    function sendVaultChildCreationRequest(
        VaultChildCreationRequest memory request
    ) external payable;

    function sendWithdrawRequest(
        WithdrawRequest memory request
    ) external payable;

    function sendValueUpdateRequest(
        ValueUpdateRequest memory request
    ) external payable;

    function updateVaultValue(ValueUpdatedRequest memory request) external;

    function getLzFee(
        GasFunctionType gasFunctionType,
        uint16 dstChainId
    ) external returns (uint256 sendFee, bytes memory adapterParams);
}