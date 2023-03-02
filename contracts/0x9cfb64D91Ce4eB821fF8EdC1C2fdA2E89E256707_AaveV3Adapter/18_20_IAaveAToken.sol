// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IAaveAToken interface
/// @author Enzyme Council <[email protected]>
/// @notice Common Aave aToken interface for V2 and V3
interface IAaveAToken {
    function UNDERLYING_ASSET_ADDRESS() external view returns (address underlying_);
}