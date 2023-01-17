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

interface IExchangeRate {
    function getBaseCurrency() external view returns (address);

    function setBaseCurrency(address _currency) external;

    function getAllCurrencyArray() external view returns (address[] memory);

    function addCurrencies(
        address[] memory _currencies,
        uint128[] memory _multipliers,
        uint128[] memory _rates
    ) external;

    function removeCurrency(address _currency) external;

    function getAllCurrencyRates() external view returns (uint256[] memory);

    function updateAllCurrencies(uint128[] memory _rates) external;

    function updateCurrency(address _currency, uint128 _rate) external;

    function getTokenToTokenAmount(
        address _fromToken,
        address _toToken,
        uint256 _amount
    ) external view returns (uint256);
}