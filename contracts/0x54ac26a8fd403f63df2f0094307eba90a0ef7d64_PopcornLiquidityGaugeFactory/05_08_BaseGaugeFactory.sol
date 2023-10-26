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

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

import {ILiquidityGauge} from "./interfaces/ILiquidityGauge.sol";

abstract contract BaseGaugeFactory {
    ILiquidityGauge private immutable _gaugeImplementation;

    mapping(address => bool) private _isGaugeFromFactory;

    event GaugeCreated(address indexed gauge);

    constructor(ILiquidityGauge gaugeImplementation) {
        _gaugeImplementation = gaugeImplementation;
    }

    /**
     * @notice Returns the address of the implementation used for gauge deployments.
     */
    function getGaugeImplementation() public view returns (ILiquidityGauge) {
        return _gaugeImplementation;
    }

    /**
     * @notice Returns true if `gauge` was created by this factory.
     */
    function isGaugeFromFactory(address gauge) external view returns (bool) {
        return _isGaugeFromFactory[gauge];
    }

    /**
     * @dev Deploys a new gauge as a proxy of the implementation in storage.
     * The deployed gauge must be initialized by the caller method.
     * @return The address of the deployed gauge
     */
    function _create(bytes32 salt) internal returns (address) {
        address gauge = Clones.cloneDeterministic(address(_gaugeImplementation), salt);

        _isGaugeFromFactory[gauge] = true;
        emit GaugeCreated(gauge);

        return gauge;
    }
}