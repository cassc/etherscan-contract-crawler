// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

library TransferHelper {
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: Transfer failed eth");
    }
}