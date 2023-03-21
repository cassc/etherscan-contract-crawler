// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

library LibTransferHelper {
    function transferETH(address receiver, uint amount) internal {
        (bool ok,) = receiver.call{value : amount}("");
        require(ok, "bad eth transfer");
    }
}