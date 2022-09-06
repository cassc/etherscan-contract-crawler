// SPDX-License-Identifier: AGPL-3.0-or-later

/// proxy.sol -- Execute DSS actions through the proxy's identity

// Copyright (C) 2022 Horsefacts <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.15;

import {DSAuth} from "ds-auth/auth.sol";
import {DSNote} from "ds-note/note.sol";

contract DSSProxy is DSAuth, DSNote {
    // --- Data ---
    address public dss;

    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth note { wards[usr] = 1; }
    function deny(address usr) external auth note { wards[usr] = 0; }
    modifier ward {
        require(wards[msg.sender] == 1, "DSSProxy/not-authorized");
        require(msg.sender != owner, "DSSProxy/owner-not-ward");
        _;
    }

    // --- Init ---
    constructor(address dss_, address usr, address god) {
        dss = dss_;
        wards[usr] = 1;
        setOwner(god);
    }

    // --- Upgrade ---
    function upgrade(address dss_) external auth note {
        dss = dss_;
    }

    // --- Proxy ---
    fallback() external ward note {
        address _dss = dss;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _dss, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}