// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

/**
 * @title Library of functions shared across DataLayr.
 * @author Layr Labs, Inc.
 */
library MiddlewareUtils {
    /// @notice Finds the `signatoryRecordHash`, used for fraudproofs.
    function computeSignatoryRecordHash(
        uint32 globalDataStoreId,
        bytes32[] memory nonSignerPubkeyHashes,
        uint256 signedStakeFirstQuorum,
        uint256 signedStakeSecondQuorum
    ) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(globalDataStoreId, nonSignerPubkeyHashes, signedStakeFirstQuorum, signedStakeSecondQuorum)
        );
    }
}