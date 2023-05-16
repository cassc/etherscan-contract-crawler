// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library VaultChildStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.VaultChild');

    struct Layout {
        bytes32 vaultId;
        uint16 parentChainId;
        address vaultParent;
        bool bridgeApproved;
        uint bridgeApprovalTime;
        uint16[] siblingChains;
        mapping(uint16 => address) siblings;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}