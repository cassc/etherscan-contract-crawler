//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library LibWaitlist {
    bytes32 public constant TYPE_HASH = keccak256("Waitlist(address owner,uint32 amount,uint32 setId)");

    struct Waitlist {
        address owner;
        uint32 amount;
        uint32 setId;
    }

    function hash(Waitlist memory _waitlist) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, _waitlist.owner, _waitlist.amount, _waitlist.setId));
    }
}