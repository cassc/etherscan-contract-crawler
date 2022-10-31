//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
    @title ImeStakingAccessControl
    @author iMe Group
    @notice Contract, implementing access control for iMe Staking v1

    @dev
                         ======================
                   ------| DEFAULT_ADMIN_ROLE | -----
                   |     ======================     |
                   |     - Manages other roles      |
                   |                                |
                   V                                V
      ========================          =======================
      | STAKING_MANAGER_ROLE |          | STAKING_BANKER_ROLE |
      ========================          =======================
      - Configures staking              - Can withdraw free tokens
      - Suitable for staking            - Suitable for staking partners
        maintainers
 */
contract ImeStakingAccessControl is AccessControl {
    /**
        @dev Role for staking management operations
     */
    bytes32 public constant STAKING_MANAGER_ROLE =
        keccak256("STAKING_MANAGER_ROLE");

    /**
        @dev Role for staking balance management
     */
    bytes32 public constant STAKING_BANKER_ROLE =
        keccak256("STAKING_BANKER_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
}