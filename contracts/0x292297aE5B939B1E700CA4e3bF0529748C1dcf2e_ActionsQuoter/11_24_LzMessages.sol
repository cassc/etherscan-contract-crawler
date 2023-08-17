// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

enum LzMessageType {
    REDEEM,
    UPDATE,
    DEPOSITED_FROM_BRIDGE,
    ZERO_DEPOSIT
}

struct RedeemMessage {
    uint256 shares;
    uint256 totalSupply;
    uint8 slippage;
}

struct UpdateMessage {
    bytes32 transferId;
}

struct DepositedFromBridgeMessage {
    uint256 totalAssetsBefore;
    uint256 totalAssetsAfter;
}

/// @author YLDR <[email protected]>
library LzMessages {
    function encodeMessage(LzMessageType messageType, bytes memory data) internal pure returns (bytes memory payload) {
        return abi.encode(messageType, data);
    }

    function encodeMessage(RedeemMessage memory message) internal pure returns (bytes memory payload) {
        return encodeMessage(LzMessageType.REDEEM, abi.encode(message));
    }

    function encodeMessage(UpdateMessage memory message) internal pure returns (bytes memory payload) {
        return encodeMessage(LzMessageType.UPDATE, abi.encode(message));
    }

    function encodeMessage(DepositedFromBridgeMessage memory message) internal pure returns (bytes memory payload) {
        return encodeMessage(LzMessageType.DEPOSITED_FROM_BRIDGE, abi.encode(message));
    }

    function decodeTypeAndData(bytes memory payload)
        internal
        pure
        returns (LzMessageType messageType, bytes memory data)
    {
        return abi.decode(payload, (LzMessageType, bytes));
    }
}