// SPDX-License-Identifier: GPL-3.0-or-later
/**
 *  Copyright (C) 2022 TXA Pte. Ltd.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *  See the GNU General Public License for more details.
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
pragma solidity 0.8.13;

interface IAcceptsDeposit {
    function migrateDeposit(address depositor, uint256 amount)
        external
        returns (bool);

    function migrateVirtualBalance(address depositor, uint256 amount)
        external
        returns (bool);

    function getMigratorAddress() external view returns (address);
}