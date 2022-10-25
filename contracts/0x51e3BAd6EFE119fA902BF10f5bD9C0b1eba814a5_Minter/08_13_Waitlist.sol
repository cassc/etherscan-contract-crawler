//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library LibWaitlist {
    bytes32 public constant TYPE_HASH = keccak256("Waitlist(address owner,uint32 amount)");

    struct Waitlist {
        address owner;
        uint32 amount;
    }

    function hash(Waitlist memory _waitlist) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, _waitlist.owner, _waitlist.amount));
    }
}