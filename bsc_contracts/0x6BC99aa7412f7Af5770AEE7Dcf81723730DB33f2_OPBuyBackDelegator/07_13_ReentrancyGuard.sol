// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        check();
        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }

    function check() private view {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
    }
}