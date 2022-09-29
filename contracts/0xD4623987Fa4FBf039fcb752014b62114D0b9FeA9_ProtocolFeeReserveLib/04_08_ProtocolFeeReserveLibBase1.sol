// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "./ProtocolFeeReserveLibBaseCore.sol";

/// @title ProtocolFeeReserveLibBase1 Contract
/// @author Enzyme Council <[email protected]>
/// @notice A base implementation for ProtocolFeeReserveLib
/// @dev Each next base implementation inherits the previous base implementation,
/// e.g., `ProtocolFeeReserveLibBase2 is ProtocolFeeReserveLibBase1`
/// DO NOT EDIT CONTRACT.
abstract contract ProtocolFeeReserveLibBase1 is ProtocolFeeReserveLibBaseCore {
    event MlnTokenBalanceWithdrawn(address indexed to, uint256 amount);

    event SharesBoughtBack(
        address indexed vaultProxy,
        uint256 sharesAmount,
        uint256 mlnValue,
        uint256 mlnBurned
    );
}