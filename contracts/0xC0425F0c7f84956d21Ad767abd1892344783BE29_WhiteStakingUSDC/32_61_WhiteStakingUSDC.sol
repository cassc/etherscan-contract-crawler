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

import "./WhiteStaking.sol";
pragma solidity 0.6.12;

contract WhiteStakingUSDC is WhiteStaking, IWhiteStakingERC20 {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    IERC20 public immutable USDC;

    constructor(ERC20 _token, ERC20 usdc) public 
        WhiteStaking(_token, "Staked WHITE", "sWHITE") {
        USDC = usdc;
    }

    function sendProfit(uint amount) external override {
        uint _totalSupply = totalSupply();
        if (_totalSupply > 0) {
            totalProfit += amount.mul(ACCURACY) / _totalSupply;
            USDC.safeTransferFrom(msg.sender, address(this), amount);
            emit Profit(amount);
        } else {
            USDC.safeTransferFrom(msg.sender, FALLBACK_RECIPIENT, amount);
        }
    }

    function _transferProfit(uint amount) internal override {
        USDC.safeTransfer(msg.sender, amount);
    }
}