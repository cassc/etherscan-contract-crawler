pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "./ProtocolFee.sol";

contract ProtocolFeeMock is ProtocolFee {
    bool public setProtocolFeeCalled;

    function initialize(uint16 _initFee) external initializer {
        __ProtocolFee_init(_initFee);
    }

    function setProtocolFee(uint16 newFee) public override onlyOwner {
        setProtocolFeeCalled = true;

        bool _isInitializing;
        assembly {
            _isInitializing := sload(1)
        }

        // Only call the actual function if we are not initializing
        if (!_isInitializing) {
            super.setProtocolFee(newFee);
        }
    }
}