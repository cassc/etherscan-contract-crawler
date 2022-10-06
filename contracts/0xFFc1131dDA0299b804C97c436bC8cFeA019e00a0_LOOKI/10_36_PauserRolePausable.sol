// SPDX-License-Identifier: MIT
// Creator: [email protected]

pragma solidity ^0.8.8;

import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';

abstract contract PauserRolePausable is AccessControlEnumerable, Pausable {
    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
    bytes32 public constant UNPAUSER_ROLE = keccak256('UNPAUSER_ROLE');

    constructor() {
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(UNPAUSER_ROLE, _msgSender());
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        Pausable._pause();
    }

    function unpause() public onlyRole(UNPAUSER_ROLE) {
        Pausable._unpause();
    }
}