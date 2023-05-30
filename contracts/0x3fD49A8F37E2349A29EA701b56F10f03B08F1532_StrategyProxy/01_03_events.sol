// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract Events {
    event setAdminLog(address oldAdmin_, address newAdmin_);

    event setDummyImplementationLog(address oldDummyImplementation_, address newDummyImplementation_);

    event setImplementationLog(address implementation_, bytes4[] sigs_);

    event removeImplementationLog(address implementation_);
}