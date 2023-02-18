// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

import "../interfaces/IQuantumBlackList.sol";

library MinterceptorStorage {
    struct Layout {
        address blackListAddress;
        address payable treasury;
        uint256 defaultPlatformFee;
        mapping(address => mapping(uint256 => uint256)) itemIdToTokenId;
        mapping(address => uint256) currentTokenId; // allows for sequential tokenId's for a given collection
        mapping(address => uint256) overridePlatformFee; // override the platform fee at collection level
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("quantum.contracts.storage.minterceptor.v1");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}