// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "./RoleConstant.sol";

abstract contract Pause is
ContextUpgradeable,
OwnableUpgradeable,
RoleConstant,
IAccessControlEnumerableUpgradeable,
AccessControlEnumerableUpgradeable
{
    bool private pause;

    modifier isPause() {
        require(pause == false);
        _;
    }

    function setPause(bool pause_) public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "You must have pauser role to pause"
        );
        pause = pause_;
    }

    function getPause() public view returns (bool) {
        return pause;
    }
}