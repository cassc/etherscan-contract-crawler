/*
 * Capital DEX
 *
 * Copyright ©️ 2020 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2020 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
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
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0;

/**
 * @dev Interface of DexWhitelist contract.
 */
interface IDexWhitelist {
    function isInvestorAddressActive(address _addr)
        external
        view
        returns (bool);

    /// @dev Returns success if address is in investor WL or liquidity WL is not active
    function isLiquidityAddressActive(address _addr)
        external
        view
        returns (bool);

    /// @dev Returns success if address is in investor WL or swap WL is not active
    function isSwapAddressActive(address _addr)
        external
        view
        returns (bool);

    /// @dev Returns success if address is in investor WL or swap WL is not active
    function isFarmAddressActive(address _addr)
        external
        view
        returns (bool);

    /// @dev Returns success if address is in token WL or token WL is not active
    function isTokenAddressActive(address _addr)
        external
        view
        returns (bool);
}