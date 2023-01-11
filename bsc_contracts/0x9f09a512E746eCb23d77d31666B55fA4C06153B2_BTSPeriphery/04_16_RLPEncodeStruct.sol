// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import "./RLPEncode.sol";
import "./Types.sol";

library RLPEncodeStruct {
    using RLPEncode for bytes;
    using RLPEncode for string;
    using RLPEncode for uint256;
    using RLPEncode for address;
    using RLPEncode for int256;

    using RLPEncodeStruct for Types.BlockHeader;
    using RLPEncodeStruct for Types.BlockWitness;
    using RLPEncodeStruct for Types.BlockUpdate;
    using RLPEncodeStruct for Types.BlockProof;
    using RLPEncodeStruct for Types.EventProof;
    using RLPEncodeStruct for Types.ReceiptProof;
    using RLPEncodeStruct for Types.Votes;
    using RLPEncodeStruct for Types.RelayMessage;

    uint8 private constant LIST_SHORT_START = 0xc0;
    uint8 private constant LIST_LONG_START = 0xf7;

    function encodeBMCService(Types.BMCService memory _bs)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory _rlp = abi.encodePacked(
            _bs.serviceType.encodeString(),
            _bs.payload.encodeBytes()
        );
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeGatherFeeMessage(Types.GatherFeeMessage memory _gfm)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory _rlp;
        bytes memory temp;
        for (uint256 i = 0; i < _gfm.svcs.length; i++) {
            temp = abi.encodePacked(_gfm.svcs[i].encodeString());
            _rlp = abi.encodePacked(_rlp, temp);
        }
        _rlp = abi.encodePacked(
            _gfm.fa.encodeString(),
            addLength(_rlp.length, false),
            _rlp
        );
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeEventMessage(Types.EventMessage memory _em)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory _rlp = abi.encodePacked(
            _em.conn.from.encodeString(),
            _em.conn.to.encodeString()
        );
        _rlp = abi.encodePacked(
            _em.eventType.encodeString(),
            addLength(_rlp.length, false),
            _rlp
        );
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeCoinRegister(string[] memory _coins)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory _rlp;
        bytes memory temp;
        for (uint256 i = 0; i < _coins.length; i++) {
            temp = abi.encodePacked(_coins[i].encodeString());
            _rlp = abi.encodePacked(_rlp, temp);
        }
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeBMCMessage(Types.BMCMessage memory _bm)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory _rlp = abi.encodePacked(
            _bm.src.encodeString(),
            _bm.dst.encodeString(),
            _bm.svc.encodeString(),
            _bm.sn.encodeInt(),
            _bm.message.encodeBytes()
        );
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeServiceMessage(Types.ServiceMessage memory _sm)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory _rlp = abi.encodePacked(
            uint256(_sm.serviceType).encodeUint(),
            _sm.data.encodeBytes()
        );
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeTransferCoinMsg(Types.TransferCoin memory _data)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory _rlp;
        bytes memory temp;
        for (uint256 i = 0; i < _data.assets.length; i++) {
            temp = abi.encodePacked(
                _data.assets[i].coinName.encodeString(),
                _data.assets[i].value.encodeUint()
            );
            _rlp = abi.encodePacked(_rlp, addLength(temp.length, false), temp);
        }
        _rlp = abi.encodePacked(
            _data.from.encodeString(),
            _data.to.encodeString(),
            addLength(_rlp.length, false),
            _rlp
        );
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeResponse(Types.Response memory _res)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory _rlp = abi.encodePacked(
            _res.code.encodeUint(),
            _res.message.encodeString()
        );
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeBlockHeader(Types.BlockHeader memory _bh)
        internal
        pure
        returns (bytes memory)
    {
        // Serialize the first 10 items in the BlockHeader
        //  patchTxHash and txHash might be empty.
        //  In that case, encoding these two items gives the result as 0xF800
        //  Similarly, logsBloom might be also empty
        //  But, encoding this item gives the result as 0x80
        bytes memory _rlp = abi.encodePacked(
            _bh.version.encodeUint(),
            _bh.height.encodeUint(),
            _bh.timestamp.encodeUint(),
            _bh.proposer.encodeBytes(),
            _bh.prevHash.encodeBytes(),
            _bh.voteHash.encodeBytes(),
            _bh.nextValidators.encodeBytes()
        );
        bytes memory temp1;
        if (_bh.patchTxHash.length != 0) {
            temp1 = _bh.patchTxHash.encodeBytes();
        } else {
            temp1 = emptyListHeadStart();
        }
        _rlp = abi.encodePacked(_rlp, temp1);

        if (_bh.txHash.length != 0) {
            temp1 = _bh.txHash.encodeBytes();
        } else {
            temp1 = emptyListHeadStart();
        }
        _rlp = abi.encodePacked(_rlp, temp1, _bh.logsBloom.encodeBytes());
        bytes memory temp2;
        //  SPR struct could be an empty struct
        //  In that case, serialize(SPR) = 0xF800
        if (_bh.isSPREmpty) {
            temp2 = emptyListHeadStart();
        } else {
            //  patchReceiptHash and receiptHash might be empty
            //  In that case, encoding these two items gives the result as 0xF800
            if (_bh.spr.patchReceiptHash.length != 0) {
                temp1 = _bh.spr.patchReceiptHash.encodeBytes();
            } else {
                temp1 = emptyListHeadStart();
            }
            temp2 = abi.encodePacked(_bh.spr.stateHash.encodeBytes(), temp1);

            if (_bh.spr.receiptHash.length != 0) {
                temp1 = _bh.spr.receiptHash.encodeBytes();
            } else {
                temp1 = emptyListHeadStart();
            }
            temp2 = abi.encodePacked(temp2, temp1);
            temp2 = abi
                .encodePacked(addLength(temp2.length, false), temp2)
                .encodeBytes();
        }
        _rlp = abi.encodePacked(_rlp, temp2);

        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeVotes(Types.Votes memory _vote)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory _rlp;
        bytes memory temp;

        //  First, serialize an array of TS
        for (uint256 i = 0; i < _vote.ts.length; i++) {
            temp = abi.encodePacked(
                _vote.ts[i].timestamp.encodeUint(),
                _vote.ts[i].signature.encodeBytes()
            );
            _rlp = abi.encodePacked(_rlp, addLength(temp.length, false), temp);
        }

        //  Next, serialize the blockPartSetID
        temp = abi.encodePacked(
            _vote.blockPartSetID.n.encodeUint(),
            _vote.blockPartSetID.b.encodeBytes()
        );
        //  Combine all of them
        _rlp = abi.encodePacked(
            _vote.round.encodeUint(),
            addLength(temp.length, false),
            temp,
            addLength(_rlp.length, false),
            _rlp
        );
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeBlockWitness(Types.BlockWitness memory _bw)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory _rlp;
        bytes memory temp;
        for (uint256 i = 0; i < _bw.witnesses.length; i++) {
            temp = _bw.witnesses[i].encodeBytes();
            _rlp = abi.encodePacked(_rlp, temp);
        }
        _rlp = abi.encodePacked(
            _bw.height.encodeUint(),
            addLength(_rlp.length, false),
            _rlp
        );
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeEventProof(Types.EventProof memory _ep)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory _rlp;
        bytes memory temp;
        for (uint256 i = 0; i < _ep.eventMptNode.length; i++) {
            temp = _ep.eventMptNode[i].encodeBytes();
            _rlp = abi.encodePacked(_rlp, temp);
        }
        _rlp = abi
            .encodePacked(addLength(_rlp.length, false), _rlp)
            .encodeBytes();

        _rlp = abi.encodePacked(_ep.index.encodeUint(), _rlp);
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeBlockUpdate(Types.BlockUpdate memory _bu)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory temp;
        bytes memory _rlp;
        //  In the case that _validators[] is an empty array, loop will be skipped
        //  and RLP_ENCODE([bytes]) == EMPTY_LIST_HEAD_START (0xF800) instead
        if (_bu.validators.length != 0) {
            for (uint256 i = 0; i < _bu.validators.length; i++) {
                temp = _bu.validators[i].encodeBytes();
                _rlp = abi.encodePacked(_rlp, temp);
            }
            _rlp = abi
                .encodePacked(addLength(_rlp.length, false), _rlp)
                .encodeBytes();
        } else {
            _rlp = emptyListHeadStart();
        }

        _rlp = abi.encodePacked(
            _bu.bh.encodeBlockHeader().encodeBytes(),
            _bu.votes.encodeVotes().encodeBytes(),
            _rlp
        );

        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeReceiptProof(Types.ReceiptProof memory _rp)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory temp;
        bytes memory _rlp;
        //  Serialize [bytes] which are transaction receipts
        for (uint256 i = 0; i < _rp.txReceipts.length; i++) {
            temp = _rp.txReceipts[i].encodeBytes();
            _rlp = abi.encodePacked(_rlp, temp);
        }
        _rlp = abi
            .encodePacked(addLength(_rlp.length, false), _rlp)
            .encodeBytes();

        bytes memory eventProof;
        for (uint256 i = 0; i < _rp.ep.length; i++) {
            temp = _rp.ep[i].encodeEventProof();
            eventProof = abi.encodePacked(eventProof, temp);
        }
        _rlp = abi.encodePacked(
            _rp.index.encodeUint(),
            _rlp,
            addLength(eventProof.length, false),
            eventProof
        );

        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeBlockProof(Types.BlockProof memory _bp)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory _rlp = abi.encodePacked(
            _bp.bh.encodeBlockHeader().encodeBytes(),
            _bp.bw.encodeBlockWitness().encodeBytes()
        );
        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    function encodeRelayMessage(Types.RelayMessage memory _rm)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory temp;
        bytes memory _rlp;
        if (_rm.buArray.length != 0) {
            for (uint256 i = 0; i < _rm.buArray.length; i++) {
                temp = _rm.buArray[i].encodeBlockUpdate().encodeBytes();
                _rlp = abi.encodePacked(_rlp, temp);
            }
            _rlp = abi.encodePacked(addLength(_rlp.length, false), _rlp);
        } else {
            _rlp = emptyListShortStart();
        }

        if (_rm.isBPEmpty == false) {
            temp = _rm.bp.encodeBlockProof();
        } else {
            temp = emptyListHeadStart();
        }
        _rlp = abi.encodePacked(_rlp, temp);

        bytes memory receiptProof;
        if (_rm.isRPEmpty == false) {
            for (uint256 i = 0; i < _rm.rp.length; i++) {
                temp = _rm.rp[i].encodeReceiptProof().encodeBytes();
                receiptProof = abi.encodePacked(receiptProof, temp);
            }
            receiptProof = abi.encodePacked(
                addLength(receiptProof.length, false),
                receiptProof
            );
        } else {
            receiptProof = emptyListShortStart();
        }
        _rlp = abi.encodePacked(_rlp, receiptProof);

        return abi.encodePacked(addLength(_rlp.length, false), _rlp);
    }

    //  Adding LIST_HEAD_START by length
    //  There are two cases:
    //  1. List contains less than or equal 55 elements (total payload of the RLP) -> LIST_HEAD_START = LIST_SHORT_START + [0-55] = [0xC0 - 0xF7]
    //  2. List contains more than 55 elements:
    //  - Total Payload = 512 elements = 0x0200
    //  - Length of Total Payload = 2
    //  => LIST_HEAD_START = \x (LIST_LONG_START + length of Total Payload) \x (Total Payload) = \x(F7 + 2) \x(0200) = \xF9 \x0200 = 0xF90200
    function addLength(uint256 length, bool isLongList)
        internal
        pure
        returns (bytes memory)
    {
        if (length > 55 && !isLongList) {
            bytes memory payLoadSize = RLPEncode.encodeUintByLength(length);
            return
                abi.encodePacked(
                    addLength(payLoadSize.length, true),
                    payLoadSize
                );
        } else if (length <= 55 && !isLongList) {
            return abi.encodePacked(uint8(LIST_SHORT_START + length));
        }
        return abi.encodePacked(uint8(LIST_LONG_START + length));
    }

    function emptyListHeadStart() internal pure returns (bytes memory) {
        bytes memory payLoadSize = RLPEncode.encodeUintByLength(0);
        return
            abi.encodePacked(
                abi.encodePacked(uint8(LIST_LONG_START + payLoadSize.length)),
                payLoadSize
            );
    }

    function emptyListShortStart() internal pure returns (bytes memory) {
        return abi.encodePacked(LIST_SHORT_START);
    }
}