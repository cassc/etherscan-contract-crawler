// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

import "../interfaces/IQuantumBlackList.sol";

library StudioDeployerStorage {
    struct Layout {
        IQuantumBlackList blacklist;
        mapping(uint256 => bool) vouchersUsed;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("quantum.contracts.storage.studiodeployer.v1");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}