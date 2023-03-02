// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IAaveV3PoolAddressProvider interface
/// @author Enzyme Council <[email protected]>
interface IAaveV3PoolAddressProvider {
    function getPool() external view returns (address pool_);
}