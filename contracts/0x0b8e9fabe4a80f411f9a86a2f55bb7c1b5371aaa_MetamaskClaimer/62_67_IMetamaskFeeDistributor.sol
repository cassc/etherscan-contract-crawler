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

pragma solidity ^0.8.0;

interface IMetamaskFeeDistributor {
    /**
     * @dev Returns the amount of ETH or ERC20 tokens a recipient can withdraw
     * @param token Token address (address(0) for ETH)
     * @param recipient Address of the recipient
     */
    function available(address token, address recipient) external view returns (uint256);

    /**
     * @dev Withdraws the specified tokens or ETH
     * @param tokens Array of tokens to withdraw
     */
    function withdraw(address[] calldata tokens) external;
}