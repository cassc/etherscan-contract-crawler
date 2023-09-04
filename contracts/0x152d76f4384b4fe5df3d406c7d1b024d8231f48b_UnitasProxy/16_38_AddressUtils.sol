// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "./Errors.sol";

library AddressUtils {
    /**
     * @notice Reverts if `account` is zero or the code size is zero
     */
    function checkContract(address account) internal view {
        checkNotZero(account);

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        _require(size > 0, Errors.ADDRESS_CODE_SIZE_ZERO);
    }

    /**
     * @notice Reverts if `account` is zero
     */
    function checkNotZero(address account) internal pure {
        _require(account != address(0), Errors.ADDRESS_ZERO);
    }
}