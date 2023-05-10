// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library MagicTokenTransferErrors {
    error TransferFailed(address token, address to, uint256 amount);
}