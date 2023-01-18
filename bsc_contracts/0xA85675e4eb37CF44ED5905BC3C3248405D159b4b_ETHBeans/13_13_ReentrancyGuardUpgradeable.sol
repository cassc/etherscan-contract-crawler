// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
abstract contract ReentrancyGuardUpgradeable {

    bool private _status;

    modifier nonReentrant() {
        require(_status != true, "ReentrancyGuard: reentrant call");
        _status = true;

        _;

        _status = false;
    }
}