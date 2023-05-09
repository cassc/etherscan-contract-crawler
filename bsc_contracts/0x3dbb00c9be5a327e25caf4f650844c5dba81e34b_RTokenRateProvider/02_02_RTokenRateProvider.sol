// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.6;

import "./interfaces/IRateProvider.sol";

/**
 * @title rToken Rate Provider
 * @notice Returns the value of Token in terms of rToken
 */
contract RTokenRateProvider is IRateProvider {
    IRateProvider public rateProvider;
    address public owner;

    constructor(IRateProvider _rateProvider) {
        rateProvider = _rateProvider;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }

    function setRateProvider(IRateProvider _rateProvider) public onlyOwner {
        rateProvider = _rateProvider;
    }

    function getRate() external view override returns (uint256) {
        return rateProvider.getRate();
    }
}