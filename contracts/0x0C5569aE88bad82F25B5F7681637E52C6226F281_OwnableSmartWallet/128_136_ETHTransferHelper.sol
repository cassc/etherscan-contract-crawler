// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

error FailedToTransfer();

/// @dev Contract that has the logic to take care of transferring ETH and can be overriden as needed
contract ETHTransferHelper {
    function _transferETH(address _recipient, uint256 _amount) internal virtual {
        if (_amount > 0) {
            (bool success,) = _recipient.call{value: _amount}("");
            if (!success) revert FailedToTransfer();
        }
    }
}