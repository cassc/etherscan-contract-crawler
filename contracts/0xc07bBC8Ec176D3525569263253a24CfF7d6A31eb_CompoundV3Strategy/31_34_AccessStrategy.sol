// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {AffineVault} from "src/vaults/AffineVault.sol";
import {BaseStrategy} from "./BaseStrategy.sol";
import {uncheckedInc} from "src/libs/Unchecked.sol";

contract AccessStrategy is BaseStrategy, AccessControl {
    bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST");

    constructor(AffineVault _vault, address[] memory strategists) BaseStrategy(_vault) {
        // Governance is admin
        _grantRole(DEFAULT_ADMIN_ROLE, vault.governance());
        _grantRole(STRATEGIST_ROLE, vault.governance());

        // Give STRATEGIST_ROLE to every address in list
        for (uint256 i = 0; i < strategists.length; i = uncheckedInc(i)) {
            _grantRole(STRATEGIST_ROLE, strategists[i]);
        }
    }

    function totalLockedValue() external virtual override returns (uint256) {
        return 0;
    }
}