// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library LibOwls {
    bytes32 constant OWLS_STORAGE_POSITION = keccak256("owls.contract.storage");

    struct OwlsStorage {
        address owlsContract;
    }

    function owlsStorage() internal pure returns (OwlsStorage storage os) {
        bytes32 position = OWLS_STORAGE_POSITION;
        assembly {
            os.slot := position
        }
    }
}