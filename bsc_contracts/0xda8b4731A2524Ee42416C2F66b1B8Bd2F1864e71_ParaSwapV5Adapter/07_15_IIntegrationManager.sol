// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Dexify Protocol.

    (c) Dexify Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IIntegrationManager interface
/// @author Dexify Council <[email protected]>
/// @notice Interface for the IntegrationManager
interface IIntegrationManager {
    enum SpendAssetsHandleType {
        None,
        Approve,
        Transfer,
        Remove
    }
}