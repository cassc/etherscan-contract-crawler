// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../persistent/vault/VaultLibBaseCore.sol";

/// @title MockVaultLib Contract
/// @author Enzyme Council <[email protected]>
/// @notice A mock VaultLib implementation that only extends VaultLibBaseCore
contract MockVaultLib is VaultLibBaseCore {
    function getAccessor() external view returns (address) {
        return accessor;
    }

    function getCreator() external view returns (address) {
        return creator;
    }

    function getMigrator() external view returns (address) {
        return migrator;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}