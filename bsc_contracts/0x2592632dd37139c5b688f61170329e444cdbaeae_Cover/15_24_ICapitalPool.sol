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

interface ICapitalPool {
    function canBuyCoverPerProduct(
        uint256 _productId,
        uint256 _amount,
        address _token
    ) external view returns (bool);

    function canBuyCover(uint256 _amount, address _token) external view returns (bool);

    function buyCoverPerProduct(
        uint256 _productId,
        uint256 _amount,
        address _token
    ) external;

    function hasTokenInStakersPool(address _token) external view returns (bool);

    function getCapacityInfo() external view returns (uint256, uint256);

    function getProductCapacityInfo(uint256[] memory _products)
        external
        view
        returns (
            address,
            uint256[] memory,
            uint256[] memory
        );

    function getProductCapacityRatio(uint256 _productId) external view returns (uint256);

    function getBaseToken() external view returns (address);

    function getCoverAmtPPMaxRatio() external view returns (uint256);

    function getCoverAmtPPInBaseToken(uint256 _productId) external view returns (uint256);

    function settlePaymentForClaim(
        address _token,
        uint256 _amount,
        uint256 _claimId
    ) external;

    function getStakingPercentageX10000() external view returns (uint256);

    function getTVLinBaseToken() external view returns (address, uint256);
}