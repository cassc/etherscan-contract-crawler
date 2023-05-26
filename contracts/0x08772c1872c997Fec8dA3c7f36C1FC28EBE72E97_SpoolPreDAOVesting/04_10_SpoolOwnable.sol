// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./interfaces/ISpoolOwner.sol";

abstract contract SpoolOwnable {
    ISpoolOwner private immutable spoolOwner;
    
    constructor(ISpoolOwner _spoolOwner) {
        require(
            address(_spoolOwner) != address(0),
            "SpoolOwnable::constructor: Spool owner contract cannot be 0 address"
        );

        spoolOwner = _spoolOwner;
    }

    function isSpoolOwner() internal view returns(bool) {
        return spoolOwner.isSpoolOwner(msg.sender);
    }

    function _onlyOwner() private view {
        require(isSpoolOwner(), "SpoolOwnable::_onlyOwner: Caller is not the Spool owner");
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }
}