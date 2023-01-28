/**
                                                         __
     _____      __      ___    ___     ___     __       /\_\    ___
    /\ '__`\  /'__`\   /'___\ / __`\  /'___\ /'__`\     \/\ \  / __`\
    \ \ \_\ \/\ \_\.\_/\ \__//\ \_\ \/\ \__//\ \_\.\_  __\ \ \/\ \_\ \
     \ \ ,__/\ \__/.\_\ \____\ \____/\ \____\ \__/.\_\/\_\\ \_\ \____/
      \ \ \/  \/__/\/_/\/____/\/___/  \/____/\/__/\/_/\/_/ \/_/\/___/
       \ \_\
        \/_/

    The sweetest DeFi portfolio manager.

**/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable-v4/proxy/utils/Initializable.sol";
import "./Roles.sol";

abstract contract AccessControlled is Initializable, Roles {
    event AuthorityUpdated(address indexed authority);

    function __AccessControlled_init(address _authority) public onlyInitializing {
        authority = IAuthority(_authority);

        emit AuthorityUpdated(_authority);
    }

    function setAuthority(address _newAuthority) external virtual requireRole(ROLE_DAO) {
        authority = IAuthority(_newAuthority);

        emit AuthorityUpdated(_newAuthority);
    }
}