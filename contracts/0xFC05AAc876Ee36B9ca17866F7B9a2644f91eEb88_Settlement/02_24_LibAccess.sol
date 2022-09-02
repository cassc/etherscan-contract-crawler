//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "../Types.sol";


library LibAccess {
    
    function hasRole(Types.AccessControl storage ac, bytes32 role, address actor) external view returns (bool) {
        return ac.roles[role][actor];
    }

    function _addRole(Types.AccessControl storage ac, bytes32 role, address actor) internal  {
        ac.roles[role][actor] = true;
    }

    function _revokeRole(Types.AccessControl storage ac, bytes32 role, address actor) internal  {
        delete ac.roles[role][actor];
    }
}