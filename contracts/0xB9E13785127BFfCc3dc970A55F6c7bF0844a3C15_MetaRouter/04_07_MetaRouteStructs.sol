// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library MetaRouteStructs {
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

    struct MetaMintTransaction {
        uint256 stableBridgingFee;
        uint256 amount;
        bytes32 externalID;
        address tokenReal;
        uint256 chainID;
        address to;
        address[] swapTokens;
        address secondDexRouter;
        bytes secondSwapCalldata;
        address finalReceiveSide;
        bytes finalCalldata;
        uint256 finalOffset;
    }

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

    struct MetaSynthesizeTransaction {
        uint256 stableBridgingFee;
        uint256 amount;
        address rtoken;
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
}