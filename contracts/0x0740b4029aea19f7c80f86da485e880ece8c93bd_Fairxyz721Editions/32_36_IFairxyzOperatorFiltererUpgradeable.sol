// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.19;

interface IFairxyzOperatorFiltererUpgradeable {
    error OnlyAdmin();

    /// @dev Emitted when the operator filter is disabled/enabled.
    event OperatorFilterDisabled(bool disabled);

    /**
     * @notice Enable/Disable Operator Filter
     * @dev Used to turn the operator filter on/off without updating the registry.
     */
    function toggleOperatorFilterDisabled() external;
}