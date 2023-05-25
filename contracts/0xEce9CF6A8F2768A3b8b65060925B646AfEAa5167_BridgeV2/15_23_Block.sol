// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

import "../utils/Bls.sol";
import "../utils/Utils.sol";
import "../utils/ZeroCopySource.sol";

library Block {

    function txRootHash(bytes calldata payload) internal pure returns (bytes32 txRootHash_) {
        txRootHash_ = Utils.bytesToBytes32(payload[72:104]);
    }

    function epochHash(bytes calldata payload) internal pure returns (bytes32 epochHash_) {
        epochHash_ = Utils.bytesToBytes32(payload[40:72]);
    }

    function decodeRequest(bytes memory payload) internal pure returns (
        bytes32 requestId,
        bytes memory data,
        address to,
        uint64 chainIdTo
    ) {
        uint256 off = 0;
        (requestId, off) = ZeroCopySource.NextHash(payload, off);
        (chainIdTo, off) = ZeroCopySource.NextUint64(payload, off);
        (to, off) = ZeroCopySource.NextAddress(payload, off);
        (data, off) = ZeroCopySource.NextVarBytes(payload, off);
    }

    function decodeEpochUpdate(bytes memory payload) internal pure returns (
        uint64 newEpochVersion,
        uint32 newEpochNum,
        bytes memory newKey,
        uint8 newEpochParticipantsCount
    ) {
        uint256 off = 0;
        (newEpochVersion, off) = ZeroCopySource.NextUint64(payload, off);
        (newEpochNum, off) = ZeroCopySource.NextUint32(payload, off);
        (newEpochParticipantsCount, off) = ZeroCopySource.NextUint8(payload, off);
        (newKey, off) = ZeroCopySource.NextVarBytes(payload, off);
    }

    function verify(
        Bls.Epoch memory epoch,
        bytes calldata blockHeader,
        bytes calldata votersPubKey,
        bytes calldata votersSignature,
        uint256 votersMask
    ) internal view {
        require(popcnt(votersMask) > (uint256(epoch.participantsCount) * 2) / 3, "Block: not enough participants");
        require(epoch.participantsCount == 255 || votersMask < (1 << epoch.participantsCount), "Block: bitmask too big");
        require(
            Bls.verifyMultisig(epoch, votersPubKey, blockHeader, votersSignature, votersMask),
            "Block: multisig mismatch"
        );
    }

    function popcnt(uint256 mask) internal pure returns (uint256 cnt) {
        cnt = 0;
        while (mask != 0) {
            mask = mask & (mask - 1);
            cnt++;
        }
    }
}