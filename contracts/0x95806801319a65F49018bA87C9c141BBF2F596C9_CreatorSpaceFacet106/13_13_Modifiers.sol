// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {KomonAccessControlBaseStorage} from "KomonAccessControlBaseStorage.sol";

contract Modifiers {
    modifier onlyAdmin() {
        require(
            KomonAccessControlBaseStorage.hasAdminRole(msg.sender),
            "Restricted to admin role."
        );
        _;
    }
}
