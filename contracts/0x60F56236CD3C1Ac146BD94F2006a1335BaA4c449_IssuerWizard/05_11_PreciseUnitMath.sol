/**
 *     SPDX-License-Identifier: Apache License 2.0
 *
 *     Copyright 2018 Set Labs Inc.
 *     Copyright 2022 Smash Works Inc.
 *
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 *     NOTICE
 *
 *     This is a modified code from Set Labs Inc. found at
 *
 *     https://github.com/SetProtocol/set-protocol-contracts
 *
 *     All changes made by Smash Works Inc. are described and documented at
 *
 *     https://docs.arch.finance/chambers
 *
 *
 *             %@@@@@
 *          @@@@@@@@@@@
 *        #@@@@@     @@@           @@                   @@
 *       @@@@@@       @@@         @@@@                  @@
 *      @@@@@@         @@        @@  @@    @@@@@ @@@@@  @@@*@@
 *     [email protected]@@@@          @@@      @@@@@@@@   @@    @@     @@  @@
 *     @@@@@(       (((((      @@@    @@@  @@    @@@@@  @@  @@
 *    @@@@@@   (((((((
 *    @@@@@#(((((((
 *    @@@@@(((((
 *      @@@((
 */
pragma solidity ^0.8.17.0;

library PreciseUnitMath {
    /**
     * Multiplies value _a by value _b (result is rounded down). It's assumed that the value _b is the significand
     * of a number with _deicmals precision, so the result of the multiplication will be divided by [10e_decimals].
     * The result can be interpreted as [wei].
     *
     * @param _a          Unsigned integer [wei]
     * @param _b          Unsigned integer [10e_decimals]
     * @param _decimals   Decimals of _b
     */
    function preciseMul(uint256 _a, uint256 _b, uint256 _decimals)
        internal
        pure
        returns (uint256)
    {
        uint256 preciseUnit = 10 ** _decimals;
        return (_a * _b) / preciseUnit;
    }

    /**
     * Multiplies value _a by value _b (result is rounded up). It's assumed that the value _b is the significand
     * of a number with _decimals precision, so the result of the multiplication will be divided by [10e_decimals].
     * The result will never reach zero. The result can be interpreted as [wei].
     *
     * @param _a          Unsigned integer [wei]
     * @param _b          Unsigned integer [10e_decimals]
     * @param _decimals   Decimals of _b
     */
    function preciseMulCeil(uint256 _a, uint256 _b, uint256 _decimals)
        internal
        pure
        returns (uint256)
    {
        if (_a == 0 || _b == 0) {
            return 0;
        }
        uint256 preciseUnit = 10 ** _decimals;
        return (((_a * _b) - 1) / preciseUnit) + 1;
    }

    /**
     * Divides value _a by value _b (result is rounded down). Value _a is scaled up to match value _b decimals.
     * The result can be interpreted as [wei].
     *
     * @param _a          Unsigned integer [wei]
     * @param _b          Unsigned integer [10e_decimals]
     * @param _decimals   Decimals of _b
     */
    function preciseDiv(uint256 _a, uint256 _b, uint256 _decimals)
        internal
        pure
        returns (uint256)
    {
        require(_b != 0, "Cannot divide by 0");

        uint256 preciseUnit = 10 ** _decimals;
        return (_a * preciseUnit) / _b;
    }

    /**
     * Divides value _a by value _b (result is rounded up or away from 0). Value _a is scaled up to match
     * value _b decimals. The result will never be zero, except when _a is zero. The result can be interpreted
     * as [wei].
     *
     * @param _a          Unsigned integer [wei]
     * @param _b          Unsigned integer [10e_decimals]
     * @param _decimals   Decimals of _b
     */
    function preciseDivCeil(uint256 _a, uint256 _b, uint256 _decimals)
        internal
        pure
        returns (uint256)
    {
        require(_b != 0, "Cannot divide by 0");

        uint256 preciseUnit = 10 ** _decimals;
        return _a > 0 ? ((((_a * preciseUnit) - 1) / _b) + 1) : 0;
    }
}