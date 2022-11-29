// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Interchain.sol";

interface IRangoSymbiosis {

    struct SymbiosisBridgeRequest {
        SymbiosisBridgeType bridgeType;
        bool hasFinalCall;
        MetaRouteTransaction metaRouteTransaction;
        SwapData swapData;
        BridgeData bridgeData;
        UserData userData;
        OtherSideData otherSideData;
        Interchain.RangoInterChainMessage imMessage;
    }

    enum SymbiosisBridgeType {META_BURN, META_SYNTHESIZE}

    struct MetaRouteTransaction {
        bytes firstSwapCalldata;
        bytes secondSwapCalldata;
        address[] approvedTokens;
        address firstDexRouter;
        address secondDexRouter;
        uint256 amount;
        bool nativeIn;
        address relayRecipient;
        bytes otherSideCalldata;
    }

    struct SwapData {
        bytes poolData;
        address poolAddress;
    }

    struct BridgeData {
        address oppositeBridge;
        uint256 chainID;
        bytes32 clientID;
    }

    struct UserData {
        address receiveSide;
        address revertableAddress;
        address token;
        address syntCaller;
    }

    struct OtherSideData {
        uint256 stableBridgingFee;
        uint256 amount;
        address chain2address;
        address[] swapTokens;
        address finalReceiveSide;
        address finalToken;
        uint256 finalAmount;
    }

    struct MetaBurnTransaction {
        uint256 stableBridgingFee;
        uint256 amount;
        address syntCaller;
        address finalReceiveSide;
        address sToken;
        bytes finalCallData;
        uint256 finalOffset;
        address chain2address;
        address receiveSide;
        address oppositeBridge;
        address revertableAddress;
        uint256 chainID;
        bytes32 clientID;
    }

    struct MetaSynthesizeTransaction {
        uint256 stableBridgingFee;
        uint256 amount;
        address rToken;
        address chain2address;
        address receiveSide;
        address oppositeBridge;
        address syntCaller;
        uint256 chainID;
        address[] swapTokens;
        address secondDexRouter;
        bytes secondSwapCalldata;
        address finalReceiveSide;
        bytes finalCalldata;
        uint256 finalOffset;
        address revertableAddress;
        bytes32 clientID;
    }

    /// @notice Executes a bridging via symbiosis
    /// @param _token The requested token to bridge
    /// @param _amount The requested amount to bridge
    /// @param _request The extra fields required by the symbiosis bridge
    function symbiosisBridge(
        address _token,
        uint256 _amount,
        SymbiosisBridgeRequest memory _request
    ) external payable;

    /// @notice Complete bridge in destination chain
    /// @param _amount The requested amount to bridge
    /// @param _token The received token after bridge
    /// @param _receivedMessage imMessage to send in destination chain
    function messageReceive(
        uint256 _amount,
        address _token,
        Interchain.RangoInterChainMessage memory _receivedMessage
    ) external payable;
}