pragma solidity 0.8.6;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2020 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import "@openzeppelin/contracts/access/AccessControl.sol";

contract LinearBondingCurve is AccessControl {
    uint256 public K; // Inf
    uint256 public START_PRICE; // 0.000018e8
    bytes32 public constant LBC_ADMIN_ROLE = keccak256("LBC_ADMIN_ROLE");

    constructor(uint256 k, uint256 startPrice) public {
        K = k;
        START_PRICE = startPrice;
    }

    function s(uint256 x0, uint256 x1) public view returns (uint256) {
        require(x1 > x0, "Hegic Amount need higher then 0");
        return
            (((x1 + x0) * (x1 - x0)) / 2 / K + START_PRICE * (x1 - x0)) / 1e18;
    }

    function setParams(uint256 _K, uint256 _START_PRICE)
        external
        onlyRole(LBC_ADMIN_ROLE)
    {
        K = _K;
        START_PRICE = _START_PRICE;
    }
}