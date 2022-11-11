// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {IVault} from "fiat/interfaces/IVault.sol";

interface IVaultSPT is IVault {
    function target() external view returns (address);
}