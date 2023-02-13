// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Events {
    event LogSetAdmin(address oldAdmin_, address newAdmin_);

    event LogSetDummyImplementation(
        address oldDummyImplementation_,
        address newDummyImplementation_
    );

    event LogSetImplementation(address implementation_, bytes4[] sigs_);

    event LogRemoveImplementation(address implementation_);
}