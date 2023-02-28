pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "../interfaces/IASResolver.sol";

/**
 * @title A base resolver contract
 */
abstract contract TellerASResolver is IASResolver {
    error NotPayable();

    function isPayable() public pure virtual override returns (bool) {
        return false;
    }

    receive() external payable virtual {
        if (!isPayable()) {
            revert NotPayable();
        }
    }
}