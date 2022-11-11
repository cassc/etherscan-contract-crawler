// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title KilnStakingPositionLibBase1 Contract
/// @author Enzyme Council <[email protected]>
/// @notice A persistent contract containing all required storage variables and
/// required functions for a KilnStakingPositionLib implementation
/// @dev DO NOT EDIT CONTRACT. If new events or storage are necessary, they should be added to
/// a numbered KilnStakingPositionLibBaseXXX that inherits the previous base.
/// e.g., `KilnStakingPositionLibBase2 is KilnStakingPositionLibBase1`
abstract contract KilnStakingPositionLibBase1 {
    event ValidatorsAdded(address stakingContractAddress, uint256 validatorAmount);

    uint256 internal validatorCount;
}