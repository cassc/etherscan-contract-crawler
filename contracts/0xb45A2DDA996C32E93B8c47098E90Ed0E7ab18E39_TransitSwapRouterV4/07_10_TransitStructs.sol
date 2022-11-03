// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library TransitStructs {

    enum SwapTypes {aggregatePreMode, aggregatePostMode, swap, cross}
    enum Flag {aggregate, swap, cross}

    struct TransitSwapDescription {
        uint8 swapType;
        address srcToken;
        address dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        string channel;
        uint256 toChainID;
        address wrappedNative;
    }

    struct CallbytesDescription {
        uint8 flag;
        address srcToken;
        bytes calldatas;
    }

    struct AggregateDescription {
        address dstToken;
        address receiver;
        uint[] amounts;
        uint[] needTransfer;
        address[] callers;
        address[] approveProxy;
        bytes[] calls;
    }

    struct SwapDescription {
        address[][] paths;
        address[][] pairs;
        uint[] fees;
        address receiver;
        uint deadline;
    }

    struct CrossDescription {
        address caller;
        uint256 amount;
        bool needWrapped;
        bytes calls;
    }

    function decodeAggregateDesc(bytes calldata calldatas) internal pure returns (AggregateDescription memory desc) {
        desc = abi.decode(calldatas, (AggregateDescription));
    }

    function decodeSwapDesc(bytes calldata calldatas) internal pure returns (SwapDescription memory desc) {
        desc = abi.decode(calldatas, (SwapDescription));
    }

    function decodeCrossDesc(bytes calldata calldatas) internal pure returns (CrossDescription memory desc) {
        desc = abi.decode(calldatas, (CrossDescription));
    }
}