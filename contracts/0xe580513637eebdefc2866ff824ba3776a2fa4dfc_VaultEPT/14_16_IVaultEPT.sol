// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {IVault} from "./IVault.sol";

interface IVaultEPT is IVault {
    function wrappedPosition() external view returns (address);

    function trancheFactory() external view returns (address);
}