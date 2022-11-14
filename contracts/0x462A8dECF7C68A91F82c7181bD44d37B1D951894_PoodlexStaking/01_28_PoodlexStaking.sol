// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../governance/community/ECOxStaking.sol";

/** @title Identifier Upgrading Process
 *
 * This contract is used to show how the upgrade process can move a contract identifier.
 * It only adds functionality to confirm that the contract is replaced.
 */
contract PoodlexStaking is ECOxStaking {
    constructor(Policy _policy, IERC20 _ecoXAddr)
        ECOxStaking(_policy, _ecoXAddr)
    {}

    function provePoodles() public pure returns (bool) {
        return true;
    }
}