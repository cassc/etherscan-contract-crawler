// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "rain.interface.interpreter/IInterpreterExternV1.sol";

library LibExtern {
    function decode(
        EncodedExternDispatch dispatch_
    ) internal pure returns (IInterpreterExternV1, ExternDispatch) {
        return (
            IInterpreterExternV1(
                address(uint160(EncodedExternDispatch.unwrap(dispatch_)))
            ),
            ExternDispatch.wrap(EncodedExternDispatch.unwrap(dispatch_) >> 160)
        );
    }
}