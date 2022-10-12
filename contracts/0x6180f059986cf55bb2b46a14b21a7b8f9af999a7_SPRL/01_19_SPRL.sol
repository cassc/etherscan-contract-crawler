// SPDX-License-Identifier: Apache-2.0
// https://docs.soliditylang.org/en/v0.8.10/style-guide.html
pragma solidity 0.8.11;

import {ERC20PresetMinterPauserUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetMinterPauserUpgradeable.sol";

/**
 * @title SPRL (Spirals Governance Token)
 * @author douglasqian
 * @notice Extension of a standard mintable, burnable, pausable ERC20
 * for Spirals governance. If you are feeling inspiraled and would like
 * to understand how SPRL supply is minted, see "ImpactVaultManager.sol"
 */
contract SPRL is ERC20PresetMinterPauserUpgradeable {
    function initialize() external initializer {
        __ERC20PresetMinterPauser_init("Spirals Governance Token", "SPRL");
    }
}