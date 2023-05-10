// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/MagicValue.sol";
import "contracts/interfaces/IERC20Transferable.sol";
import "contracts/interfaces/IMagicTokenTransfer.sol";
import "contracts/libraries/errors/MagicTokenTransferErrors.sol";

abstract contract MagicTokenTransfer is MagicValue {
    function _safeTransferTokenWithMagic(
        IERC20Transferable token_,
        IMagicTokenTransfer to_,
        uint256 amount_
    ) internal {
        bool success = token_.approve(address(to_), amount_);
        if (!success) {
            revert MagicTokenTransferErrors.TransferFailed(address(token_), address(to_), amount_);
        }
        to_.depositToken(_getMagic(), amount_);
        token_.approve(address(to_), 0);
    }
}