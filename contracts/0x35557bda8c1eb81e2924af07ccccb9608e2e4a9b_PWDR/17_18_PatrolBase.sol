// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { AltitudeBase } from "./AltitudeBase.sol";
import { IAddressRegistry } from "../interfaces/IAddressRegistry.sol";
import { IAccessControl } from "../interfaces/IAccessControl.sol";

contract PatrolBase is AltitudeBase {
    modifier HasPatrol(bytes memory _patrol) {
        require(
            IAccessControl(snowPatrolAddress()).hasRole(keccak256(_patrol), address(_msgSender())),
            "Account does not have sufficient role to call this function"
        );
        _;
    }

    function hasPatrol(bytes memory _patrol, address _address)
        internal
        view
        returns (bool)
    {
        return IAccessControl(snowPatrolAddress()).hasRole(keccak256(_patrol), _address);
    }
}