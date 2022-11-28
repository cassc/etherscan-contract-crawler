// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IGetRollupInfo {
    function getRollupInfo(
        uint8 originDomainID,
        bytes32 resourceID,
        uint64 nonce
    )
        external
        view
        returns (
            address,
            bytes32,
            uint64
        );
}