// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import { ERC20MetadataStorage } from "./ERC20MetadataStorage.sol";

/**
 * @title ERC20Metadata internal functions
 */
abstract contract ERC20MetadataInternal {
    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function _decimals() internal view virtual returns (uint8) {
        return ERC20MetadataStorage.layout().decimals;
    }

    function _decimalsLocked() internal view virtual returns (bool) {
        return ERC20MetadataStorage.layout().decimalsLocked;
    }

    function _setDecimals(uint8 decimals_) internal virtual {
        require(!_decimalsLocked(), "ERC20Metadata: decimals locked");
        ERC20MetadataStorage.layout().decimals = decimals_;
        ERC20MetadataStorage.layout().decimalsLocked = true;
    }

    function _setDecimalsLocked(bool decimalsLocked_) internal virtual {
        ERC20MetadataStorage.layout().decimalsLocked = decimalsLocked_;
    }
}