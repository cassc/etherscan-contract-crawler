// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

library LibShare {
    uint16 public constant SHARE_DENOMINATOR = 10000;

    struct Share {
        address account;
        uint16 value;
    }

    bytes32 private constant SHARE_TYPE_HASH = keccak256("Share(address account,uint16 value)");

    function hash(Share calldata share) internal pure returns (bytes32) {
        return keccak256(abi.encode(SHARE_TYPE_HASH, share.account, share.value));
    }
}