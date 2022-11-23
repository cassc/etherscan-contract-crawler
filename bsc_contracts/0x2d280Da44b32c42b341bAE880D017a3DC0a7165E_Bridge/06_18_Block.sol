// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../utils/Bls.sol";
import "../utils/Utils.sol";
import "../utils/ZeroCopySource.sol";

library Block {
    function transactionsRoot(bytes calldata _payload) internal pure returns (bytes32 txRootHash) {
        txRootHash = Utils.bytesToBytes32(_payload[72:104]);
    }

    function oracleRequestTx(bytes memory _payload)
        internal
        pure
        returns (
            bytes32 reqId,
            bytes32 bridgeFrom,
            address receiveSide,
            bytes memory sel
        )
    {
        uint256 off = 0;
        (reqId, off) = ZeroCopySource.NextHash(_payload, off);
        (bridgeFrom, off) = ZeroCopySource.NextHash(_payload, off);
        (receiveSide, off) = ZeroCopySource.NextAddress(_payload, off);
        (sel, off) = ZeroCopySource.NextVarBytes(_payload, off);
    }

    function solanaRequestTx(bytes memory _payload)
        internal
        pure
        returns (
            bytes32 reqId,
            bytes32 bridgeFrom,
            bytes32 oppositeBridge,
            bytes memory sel
        )
    {
        uint256 off = 0;
        (reqId, off) = ZeroCopySource.NextHash(_payload, off);
        (bridgeFrom, off) = ZeroCopySource.NextHash(_payload, off);
        (oppositeBridge, off) = ZeroCopySource.NextHash(_payload, off);
        (sel, off) = ZeroCopySource.NextVarBytes(_payload, off);
    }

    function epochRequestTx(bytes memory _payload)
        internal
        pure
        returns (
            uint32 txNewEpochNum,
            bytes memory txNewKey,
            uint8 txNewEpochParticipantsNum
        )
    {
        uint256 off = 0;
        (txNewEpochNum, off) = ZeroCopySource.NextUint32(_payload, off);
        (txNewEpochParticipantsNum, off) = ZeroCopySource.NextUint8(_payload, off);
        (txNewKey, off) = ZeroCopySource.NextVarBytes(_payload, off);
    }

    function verify(
        bytes calldata _blockHeader,
        bytes calldata _votersPubKey,
        bytes calldata _votersSignature,
        uint256 _votersMask,
        Bls.E2Point memory _epochKey,
        uint8 _epochParticipantsNum
    ) internal view {
        Bls.E2Point memory votersPubKey = Bls.decodeE2Point(_votersPubKey);
        Bls.E1Point memory votersSignature = Bls.decodeE1Point(_votersSignature);
        require(popcnt(_votersMask) > (uint256(_epochParticipantsNum) * 2) / 3, "not enough participants");
        require(_epochParticipantsNum == 255 || _votersMask < (1 << _epochParticipantsNum), "bitmask too big");
        require(
            Bls.verifyMultisig(_epochKey, votersPubKey, _blockHeader, votersSignature, _votersMask),
            "multisig mismatch"
        );
    }

    function popcnt(uint256 mask) internal pure returns (uint256 cnt) {
        while (mask != 0) {
            mask = mask & (mask - 1);
            cnt++;
        }
    }
}