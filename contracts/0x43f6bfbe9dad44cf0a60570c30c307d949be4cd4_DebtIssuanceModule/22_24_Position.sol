/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SignedSafeMath} from "@openzeppelin/contracts/math/SignedSafeMath.sol";

import {IJasperVault} from "../../interfaces/IJasperVault.sol";
import {PreciseUnitMath} from "../../lib/PreciseUnitMath.sol";

/**
 * @title Position
 * @author Set Protocol
 *
 * Collection of helper functions for handling and updating JasperVault Positions
 *
 * CHANGELOG:
 *  - Updated editExternalPosition to work when no external position is associated with module
 */
library Position {
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SafeCast for int256;
    using SignedSafeMath for int256;
    using PreciseUnitMath for uint256;

    /* ============ Helper ============ */

    /**
     * Returns whether the JasperVault has a default position for a given component (if the real unit is > 0)
     */
    function hasDefaultPosition(
	IJasperVault _jasperVault,
	address _component
    ) internal view returns (bool) {
	return _jasperVault.getDefaultPositionRealUnit(_component) > 0;
    }

    /**
     * Returns whether the JasperVault has an external position for a given component (if # of position modules is > 0)
     */
    function hasExternalPosition(
	IJasperVault _jasperVault,
	address _component
    ) internal view returns (bool) {
	return _jasperVault.getExternalPositionModules(_component).length > 0;
    }

    /**
     * Returns whether the JasperVault component default position real unit is greater than or equal to units passed in.
     */
    function hasSufficientDefaultUnits(
	IJasperVault _jasperVault,
	address _component,
	uint256 _unit
    ) internal view returns (bool) {
	return
	_jasperVault.getDefaultPositionRealUnit(_component) >=
	_unit.toInt256();
    }

    /**
     * Returns whether the JasperVault component external position is greater than or equal to the real units passed in.
     */
    function hasSufficientExternalUnits(
	IJasperVault _jasperVault,
	address _component,
	address _positionModule,
	uint256 _unit
    ) internal view returns (bool) {
	return
	_jasperVault.getExternalPositionRealUnit(
	    _component,
	    _positionModule
	) >= _unit.toInt256();
    }

    /**
     * If the position does not exist, create a new Position and add to the JasperVault. If it already exists,
     * then set the position units. If the new units is 0, remove the position. Handles adding/removing of
     * components where needed (in light of potential external positions).
     *
     * @param _jasperVault           Address of JasperVault being modified
     * @param _component          Address of the component
     * @param _newUnit            Quantity of Position units - must be >= 0
     */
    function editDefaultPosition(
	IJasperVault _jasperVault,
	address _component,
	uint256 _newUnit
    ) internal {
	bool isPositionFound = hasDefaultPosition(_jasperVault, _component);
	if (!isPositionFound && _newUnit > 0) {
	    // If there is no Default Position and no External Modules, then component does not exist
	    if (!hasExternalPosition(_jasperVault, _component)) {
		_jasperVault.addComponent(_component);
	    }
	} else if (isPositionFound && _newUnit == 0) {
	    // If there is a Default Position and no external positions, remove the component
	    if (!hasExternalPosition(_jasperVault, _component)) {
		_jasperVault.removeComponent(_component);
	    }
	}
	_jasperVault.editDefaultPositionUnit(_component, _newUnit.toInt256());
    }

    function editCoinType(
	IJasperVault _jasperVault,
	address _component,
	uint256 coinType
    ) internal {
	_jasperVault.editDefaultPositionCoinType(_component, coinType);
    }

    function editExternalCoinType(
	IJasperVault _jasperVault,
	address _component,
	address _module,
	uint256 coinType
    ) internal {
	_jasperVault.editExternalPositionCoinType(
	    _component,
	    _module,
	    coinType
	);
    }

    /**
     * Update an external position and remove and external positions or components if necessary. The logic flows as follows:
     * 1) If component is not already added then add component and external position.
     * 2) If component is added but no existing external position using the passed module exists then add the external position.
     * 3) If the existing position is being added to then just update the unit and data
     * 4) If the position is being closed and no other external positions or default positions are associated with the component
     *    then untrack the component and remove external position.
     * 5) If the position is being closed and other existing positions still exist for the component then just remove the
     *    external position.
     *
     * @param _jasperVault         JasperVault being updated
     * @param _component        Component position being updated
     * @param _module           Module external position is associated with
     * @param _newUnit          Position units of new external position
     * @param _data             Arbitrary data associated with the position
     */
    function editExternalPosition(
	IJasperVault _jasperVault,
	address _component,
	address _module,
	int256 _newUnit,
	bytes memory _data
    ) internal {
	if (_newUnit != 0) {
	    if (!_jasperVault.isComponent(_component)) {
		_jasperVault.addComponent(_component);
	    }
	    if (!_jasperVault.isExternalPositionModule(_component, _module)) {
		_jasperVault.addExternalPositionModule(_component, _module);
	    }
	    _jasperVault.editExternalPositionUnit(
		_component,
		_module,
		_newUnit
	    );
	    _jasperVault.editExternalPositionData(_component, _module, _data);
	} else {
	    require(_data.length == 0, "Passed data must be null");
	    // If no default or external position remaining then remove component from components array
	    if (
		_jasperVault.getExternalPositionRealUnit(_component, _module) !=
		0
	    ) {
		address[] memory positionModules = _jasperVault
		.getExternalPositionModules(_component);
		if (
		    _jasperVault.getDefaultPositionRealUnit(_component) == 0 &&
		    positionModules.length == 1
		) {
		    require(
			positionModules[0] == _module,
			"External positions must be 0 to remove component"
		    );
		    _jasperVault.removeComponent(_component);
		}
		_jasperVault.removeExternalPositionModule(_component, _module);
	    }
	}
    }

    /**
     * Get total notional amount of Default position
     *
     * @param _setTokenSupply     Supply of JasperVault in precise units (10^18)
     * @param _positionUnit       Quantity of Position units
     *
     * @return                    Total notional amount of units
     */
    function getDefaultTotalNotional(
	uint256 _setTokenSupply,
	uint256 _positionUnit
    ) internal pure returns (uint256) {
	return _setTokenSupply.preciseMul(_positionUnit);
    }

    /**
     * Get position unit from total notional amount
     *
     * @param _setTokenSupply     Supply of JasperVault in precise units (10^18)
     * @param _totalNotional      Total notional amount of component prior to
     * @return                    Default position unit
     */
    function getDefaultPositionUnit(
	uint256 _setTokenSupply,
	uint256 _totalNotional
    ) internal pure returns (uint256) {
	return _totalNotional.preciseDiv(_setTokenSupply);
    }

    /**
     * Get the total tracked balance - total supply * position unit
     *
     * @param _jasperVault           Address of the JasperVault
     * @param _component          Address of the component
     * @return                    Notional tracked balance
     */
    function getDefaultTrackedBalance(
	IJasperVault _jasperVault,
	address _component
    ) internal view returns (uint256) {
	int256 positionUnit = _jasperVault.getDefaultPositionRealUnit(
	    _component
	);
	return _jasperVault.totalSupply().preciseMul(positionUnit.toUint256());
    }

    /**
     * Calculates the new default position unit and performs the edit with the new unit
     *
     * @param _jasperVault                 Address of the JasperVault
     * @param _component                Address of the component
     * @param _setTotalSupply           Current JasperVault supply
     * @param _componentPreviousBalance Pre-action component balance
     * @return                          Current component balance
     * @return                          Previous position unit
     * @return                          New position unit
     */
    function calculateAndEditDefaultPosition(
	IJasperVault _jasperVault,
	address _component,
	uint256 _setTotalSupply,
	uint256 _componentPreviousBalance
    ) internal returns (uint256, uint256, uint256) {
	uint256 currentBalance = IERC20(_component).balanceOf(
	    address(_jasperVault)
	);
	uint256 positionUnit = _jasperVault
	.getDefaultPositionRealUnit(_component)
	.toUint256();

	uint256 newTokenUnit;
	if (currentBalance > 0) {
	    newTokenUnit = calculateDefaultEditPositionUnit(
		_setTotalSupply,
		_componentPreviousBalance,
		currentBalance,
		positionUnit
	    );
	} else {
	    newTokenUnit = 0;
	}

	editDefaultPosition(_jasperVault, _component, newTokenUnit);

	return (currentBalance, positionUnit, newTokenUnit);
    }

    /**
     * Calculate the new position unit given total notional values pre and post executing an action that changes JasperVault state
     * The intention is to make updates to the units without accidentally picking up airdropped assets as well.
     *
     * @param _setTokenSupply     Supply of JasperVault in precise units (10^18)
     * @param _preTotalNotional   Total notional amount of component prior to executing action
     * @param _postTotalNotional  Total notional amount of component after the executing action
     * @param _prePositionUnit    Position unit of JasperVault prior to executing action
     * @return                    New position unit
     */
    function calculateDefaultEditPositionUnit(
	uint256 _setTokenSupply,
	uint256 _preTotalNotional,
	uint256 _postTotalNotional,
	uint256 _prePositionUnit
    ) internal pure returns (uint256) {
	// If pre action total notional amount is greater then subtract post action total notional and calculate new position units
	uint256 airdroppedAmount = _preTotalNotional.sub(
	    _prePositionUnit.preciseMul(_setTokenSupply)
	);
	return
	_postTotalNotional.sub(airdroppedAmount).preciseDiv(
	    _setTokenSupply
	);
    }
}