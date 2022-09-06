/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.4;

interface IPool {
    function sellNXM(uint256 tokenAmount, uint256 minEthOut) external;

    function sellNXMTokens(uint256 tokenAmount) external;

    function buyNXM(uint256 minTokensOut) external payable;

    function getEthForNXM(uint256 priceInNXM) external returns (uint256);
}