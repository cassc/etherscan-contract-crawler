// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {UintUtils} from "UintUtils.sol";

library AddressUtils {
    using UintUtils for uint256;

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{value: amount}("");
        require(success, "AddressUtils: failed to send value");
    }
}
