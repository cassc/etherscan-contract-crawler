// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Operation.sol";

abstract contract Restrict is Operation {
    struct Locked {
        bool isVaild;
    }

    mapping(address => Locked) _locked;

    modifier isSafe() {
        _checkLock(_msgSender());
        _;
    }

    function addMember(address m) public onlyOwner {
        require(_locked[m].isVaild == false, "Restrict: account already exists");
        _locked[m].isVaild = true;
    }

    function addMembers(address[10] memory ms) public onlyOwner {
        uint256 i = 0;
        while (i < 10) {
            addMember(ms[i]);
        }
    }

    function unlock(address m) public onlyOwner {
        require(_locked[m].isVaild == true, "Restrict: account already exists");
        _locked[m].isVaild = false;
    }

    function _checkLock(address m) internal view {
        require(_locked[m].isVaild == false, "Restrict: account is locked");
    }
}