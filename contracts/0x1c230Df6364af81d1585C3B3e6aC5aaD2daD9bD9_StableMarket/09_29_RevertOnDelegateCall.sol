// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "../Errors.sol";

contract RevertOnDelegateCall {
    address private immutable _thisAddress;

    modifier revertOnDelegateCall() {
        _revertOnDelegateCall();
        _;
    }

    function _revertOnDelegateCall() internal view {
        // revert when calling this contract via DELEGATECALL
        if (address(this) != _thisAddress) {
            revert Errors.CloberError(Errors.DELEGATE_CALL);
        }
    }

    constructor() {
        _thisAddress = address(this);
    }
}