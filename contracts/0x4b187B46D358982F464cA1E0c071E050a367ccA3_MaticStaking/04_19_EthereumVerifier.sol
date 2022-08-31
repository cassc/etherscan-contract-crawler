// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "./CallDataRLPReader.sol";
import "./Utils.sol";
import "../interfaces/IBridge.sol";

library EthereumVerifier {
    bytes32 constant TOPIC_PEG_IN_LOCKED =
        keccak256(
            "DepositLocked(uint256,address,address,address,address,uint256,(bytes32,bytes32,uint256,address,bytes32))"
        );
    bytes32 constant TOPIC_PEG_IN_BURNED =
        keccak256(
            "DepositBurned(uint256,address,address,address,address,uint256,(bytes32,bytes32,uint256,address,bytes32),address)"
        );

    enum PegInType {
        None,
        Lock,
        Burn
    }

    struct State {
        bytes32 receiptHash;
        address contractAddress;
        uint256 chainId;
        address fromAddress;
        address payable toAddress;
        address fromToken;
        address toToken;
        uint256 totalAmount;
        // metadata fields (we can't use Metadata struct here because of Solidity struct memory layout)
        bytes32 symbol;
        bytes32 name;
        uint256 originChain;
        address originAddress;
        bytes32 bondMetadata;
        address originToken;
    }

    function getMetadata(State memory state)
        internal
        pure
        returns (IBridge.Metadata memory)
    {
        IBridge.Metadata memory metadata;
        assembly {
            metadata := add(state, 0x100)
        }
        return metadata;
    }

    function parseTransactionReceipt(uint256 receiptOffset)
        internal
        view
        returns (State memory, PegInType pegInType)
    {
        State memory state;
        /* parse peg-in data from logs */
        uint256 iter = CallDataRLPReader.beginIteration(receiptOffset + 0x20);
        {
            /* postStateOrStatus - we must ensure that tx is not reverted */
            uint256 statusOffset = iter;
            iter = CallDataRLPReader.next(iter);
            require(
                CallDataRLPReader.payloadLen(
                    statusOffset,
                    iter - statusOffset
                ) == 1,
                "tx is reverted"
            );
        }
        /* skip cumulativeGasUsed */
        iter = CallDataRLPReader.next(iter);
        /* logs - we need to find our logs */
        uint256 logs = iter;
        iter = CallDataRLPReader.next(iter);
        uint256 logsIter = CallDataRLPReader.beginIteration(logs);
        for (; logsIter < iter; ) {
            uint256 log = logsIter;
            logsIter = CallDataRLPReader.next(logsIter);
            /* make sure there is only one peg-in event in logs */
            PegInType logType = _decodeReceiptLogs(state, log);
            if (logType != PegInType.None) {
                require(pegInType == PegInType.None, "multiple logs");
                pegInType = logType;
            }
        }
        /* don't allow to process if peg-in type is unknown */
        // require(pegInType != PegInType.None, "missing logs");
        return (state, pegInType);
    }

    function _decodeReceiptLogs(State memory state, uint256 log)
        internal
        pure
        returns (PegInType pegInType)
    {
        uint256 logIter = CallDataRLPReader.beginIteration(log);
        address contractAddress;
        {
            /* parse smart contract address */
            uint256 addressOffset = logIter;
            logIter = CallDataRLPReader.next(logIter);
            contractAddress = CallDataRLPReader.toAddress(addressOffset);
        }
        /* topics */
        bytes32 mainTopic;
        address fromAddress;
        address toAddress;
        {
            uint256 topicsIter = logIter;
            logIter = CallDataRLPReader.next(logIter);
            // Must be 3 topics RLP encoded: event signature, fromAddress, toAddress
            // Each topic RLP encoded is 33 bytes (0xa0[32 bytes data])
            // Total payload: 99 bytes. Since it's list with total size bigger than 55 bytes we need 2 bytes prefix (0xf863)
            // So total size of RLP encoded topics array must be 101
            if (CallDataRLPReader.itemLength(topicsIter) != 101) {
                return PegInType.None;
            }
            topicsIter = CallDataRLPReader.beginIteration(topicsIter);
            mainTopic = bytes32(CallDataRLPReader.toUintStrict(topicsIter));
            topicsIter = CallDataRLPReader.next(topicsIter);
            fromAddress = address(
                bytes20(uint160(CallDataRLPReader.toUintStrict(topicsIter)))
            );

            topicsIter = CallDataRLPReader.next(topicsIter);
            toAddress = address(
                bytes20(uint160(CallDataRLPReader.toUintStrict(topicsIter)))
            );
            topicsIter = CallDataRLPReader.next(topicsIter);
            require(topicsIter == logIter); // safety check that iteration is finished
        }
        uint256 ptr = CallDataRLPReader.rawDataPtr(logIter);
        logIter = CallDataRLPReader.next(logIter);
        uint256 len = logIter - ptr;
        {
            // parse logs based on topic type and check that event data has correct length
            uint256 expectedLen;
            if (mainTopic == TOPIC_PEG_IN_LOCKED) {
                expectedLen = 0x120;
                pegInType = PegInType.Lock;
            } else if (mainTopic == TOPIC_PEG_IN_BURNED) {
                expectedLen = 0x140;
                pegInType = PegInType.Burn;
            } else {
                return PegInType.None;
            }
            if (len != expectedLen) {
                return PegInType.None;
            }
        }
        {
            // read chain id separately and verify that contract that emitted event is relevant
            uint256 chainId;
            assembly {
                chainId := calldataload(ptr)
            }
            //    if (chainId != Utils.currentChain()) return PegInType.None;
            // All checks are passed after this point, no errors allowed and we can modify state
            state.chainId = chainId;
            ptr += 0x20;
            len -= 0x20;
        }

        {
            uint256 structOffset;
            assembly {
                // skip 5 fields: receiptHash, contractAddress, chainId, fromAddress, toAddress
                structOffset := add(state, 0xa0)
                calldatacopy(structOffset, ptr, len)
            }
        }

        state.contractAddress = contractAddress;
        state.fromAddress = fromAddress;
        state.toAddress = payable(toAddress);
        return pegInType;
    }
}