/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

interface ICoverQuotation {
    function getGrossUnitCost(uint256 productId)
        external
        view
        returns (uint256);

    function getGrossUnitCosts(uint256[] memory products)
        external
        view
        returns (uint256[] memory);

    function getAllGrossUnitCosts()
        external
        view
        returns (uint256[] memory, uint256[] memory);

    function getPremium(
        uint256[] memory products,
        uint256[] memory durationInDays,
        uint256[] memory amounts,
        address currency
    ) external view returns (uint256, uint256);
}