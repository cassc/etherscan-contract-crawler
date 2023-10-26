// SPDX-License-Identifier: GPL-3.0
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import {IVaultRegistry, VaultMetadata} from "popcorn/src/interfaces/vault/IVaultRegistry.sol";

import {Bytes32AddressLib} from "solmate/utils/Bytes32AddressLib.sol";
import {Owned} from "solmate/auth/Owned.sol";

import {BaseGaugeFactory} from "./BaseGaugeFactory.sol";
import {ILiquidityGauge} from "./interfaces/ILiquidityGauge.sol";

contract PopcornLiquidityGaugeFactory is BaseGaugeFactory, Owned {
    using Bytes32AddressLib for address;

    error PopcornLiquidityGaugeFactory__InvalidVault();

    address public immutable gaugeAdmin;
    IVaultRegistry public immutable popcornVaultRegistry;

    constructor(
        ILiquidityGauge gaugeTemplate,
        address gaugeAdmin_,
        IVaultRegistry popcornVaultRegistry_
    ) BaseGaugeFactory(gaugeTemplate) Owned(gaugeAdmin_) {
        popcornVaultRegistry = popcornVaultRegistry_;
        gaugeAdmin = gaugeAdmin_;
    }

    /**
     * @notice Deploys a new gauge.
     * @param relativeWeightCap The relative weight cap for the created gauge
     * @return The address of the deployed gauge
     */
    function create(address vaultAddr, uint256 relativeWeightCap) onlyOwner external returns (address) {
        VaultMetadata memory vault = popcornVaultRegistry.getVault(vaultAddr);
        if (vault.vault != vaultAddr) revert PopcornLiquidityGaugeFactory__InvalidVault();

        // this will fail if there's a gauge for the given vault.
        address gauge = _create(vaultAddr.fillLast12Bytes());
        ILiquidityGauge(gauge).initialize(
            vaultAddr, relativeWeightCap, gaugeAdmin
        );
        return gauge;
    }
}