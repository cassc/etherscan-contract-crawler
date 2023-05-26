// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2022 Dai Foundation
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
pragma solidity 0.8.13;

interface INetworkTreasury {

	/**
	 * @dev This should return an estimate of the total value of the buffer in DAI.
	 * Keeper Networks should convert non-DAI assets to DAI value via an oracle.
	 * 
	 * Ex) If the network bulk trades DAI for ETH then the value of the ETH sitting
	 * in the treasury should count towards this buffer size.
	 */
	function getBufferSize() external view returns (uint256);

}