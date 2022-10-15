// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRefTreeStorage} from './Interfaces.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

abstract contract RefProgramBase is Ownable {
    IRefTreeStorage public refTreeStorage;

    constructor(IRefTreeStorage refTreeStorage_) {
        setRefTreeStorage(refTreeStorage_);
    }

    // SETTERS

    function setRefTreeStorage(IRefTreeStorage refTreeStorage_) public onlyOwner {
        refTreeStorage = refTreeStorage_;
    }

    // INTERNAL OPERATIONS

    function _trySetReferer(address user, address referer) internal {
        refTreeStorage.setReferer(user, referer);
    }
}