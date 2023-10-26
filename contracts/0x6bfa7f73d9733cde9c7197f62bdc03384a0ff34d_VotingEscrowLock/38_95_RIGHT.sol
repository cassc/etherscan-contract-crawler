//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma abicoder v2;

import "../../core/governance/libraries/VotingEscrowToken.sol";

contract RIGHT is VotingEscrowToken {
    function decimals() public pure override returns (uint8) {
        return 18;
    }
}