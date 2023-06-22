/*
 * Copyright (C) 2022  Christian Felde
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
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
pragma solidity ^0.8.0;

import "./NuPoW.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";

contract Crystal is NuPoW, ERC20FlashMint {
    uint public immutable MAX_TOTAL_MINT;
    uint public totalMint;

    constructor(
        string memory _NAME,
        string memory _SYMBOL,
        uint _MAX_TOTAL_MINT
    ) ERC20(_NAME, _SYMBOL) NuPoW(37, 60, 30 minutes) {
        MAX_TOTAL_MINT = _MAX_TOTAL_MINT;
    }

    function flashFee(
        address token,
        uint amount
    ) public view virtual override returns (uint) {
        require(token == address(this), "ERC20FlashMint: wrong token");
        amount;
        return nextMint;
    }

    function cap() public view virtual returns (uint) {
        return MAX_TOTAL_MINT;
    }

    function mint(
        uint seed,
        string memory tag
    ) public override returns (
        uint mintValue,
        bool progress
    ) {
        (mintValue, progress) = super.mint(seed, tag);

        if (totalMint + mintValue > MAX_TOTAL_MINT) mintValue = 0;

        if (mintValue > 0) {
            totalMint += mintValue;
            _mint(msg.sender, mintValue);
        }
    }
}