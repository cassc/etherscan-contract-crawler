// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

import { IConfigurationManager } from "../interfaces/IConfigurationManager.sol";

/**
 * @title Capped
 * @notice Mixin responsible for managing Vault's cap
 * @author Pods Finance
 */
abstract contract Capped {
    IConfigurationManager private immutable _configuration;
    uint256 public spentCap;

    error Capped__AmountExceedsCap(uint256 amount, uint256 available);

    constructor(IConfigurationManager _configuration_) {
        _configuration = _configuration_;
    }

    /**
     * @dev Returns the amount that could be used.
     */
    function availableCap() public view returns (uint256) {
        uint256 cap = _configuration.getCap(address(this));
        return cap == 0 ? type(uint256).max : cap - spentCap;
    }

    /**
     * @dev Increase the amount of cap used.
     * @param amount The amount to be spent
     */
    function _spendCap(uint256 amount) internal {
        uint256 available = availableCap();
        if (amount > available) revert Capped__AmountExceedsCap(amount, available);
        spentCap += amount;
    }

    /**
     * @dev Restores the cap.
     * @param amount The amount to be restored
     */
    function _restoreCap(uint256 amount) internal {
        if (availableCap() != type(uint256).max) {
            spentCap -= amount;
        }
    }
}