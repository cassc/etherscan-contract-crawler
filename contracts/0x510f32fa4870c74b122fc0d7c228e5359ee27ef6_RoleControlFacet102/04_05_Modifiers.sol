// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {KomonAccessControlBaseStorage} from "KomonAccessControlBaseStorage.sol";

contract Modifiers {
    modifier onlyKomonWeb() {
        require(
            KomonAccessControlBaseStorage.hasKomonWebRole(msg.sender) ||
                KomonAccessControlBaseStorage.hasAdminRole(msg.sender),
            "Restricted to komon web role."
        );
        _;
    }
}
