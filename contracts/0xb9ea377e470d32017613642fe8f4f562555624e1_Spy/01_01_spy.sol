// SPDX-License-Identifier: AGPL-3.0-or-later

/// spy.sol -- Counter read module

// Copyright (C) 2022 Horsefacts <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.15;

interface SumLike {
    function incs(address) external view returns (uint256,uint256,uint256,uint256);
}

contract Spy {
    // --- Data ---
    SumLike immutable public sum;

    // --- Init ---
    constructor(address sum_) {
        sum = SumLike(sum_);
    }

    // --- Counter Read ---
    function see() external view returns (uint256 net) {
        (net,,,) = sum.incs(msg.sender);
    }
}