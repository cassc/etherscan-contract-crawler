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

interface ICoverConfig {
    function getAllValidCurrencyArray() external view returns (address[] memory);

    function isValidCurrency(address currency) external view returns (bool);

    function getMinDurationInDays() external view returns (uint256);

    function getMaxDurationInDays() external view returns (uint256);

    function getMinAmountOfCurrency(address currency) external view returns (uint256);

    function getMaxAmountOfCurrency(address currency) external view returns (uint256);

    function getCoverConfigDetails()
        external
        view
        returns (
            uint256,
            uint256,
            address[] memory,
            uint256[] memory,
            uint256[] memory
        );

    function getMaxClaimDurationInDaysAfterExpired() external view returns (uint256);

    function getInsurTokenRewardPercentX10000() external view returns (uint256);

    function getCancelCoverFeeRateX10000() external view returns (uint256);
}