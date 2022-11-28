// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../../utils/rollup/RollupTypes.sol";

interface ISettle {
    function settle(
        uint8 originDomainID,
        bytes32 resourceID,
        uint64 nonce,
        bytes32[] calldata proof,
        bytes32 rootHash,
        bytes calldata data
    ) external;
}