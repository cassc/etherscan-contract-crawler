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

pragma solidity >=0.7.0 <0.9.0;

import "./IVotingEscrow.sol";
import "./IOmniVotingEscrow.sol";

interface IVotingEscrowRemapper {
    /**
     * @notice Returns Voting Escrow contract address.
     */
    function getVotingEscrow() external view returns (IVotingEscrow);

    //    /**
    //     * @notice Returns Omni Voting Escrow contract address).
    //     */
    //    function getOmniVotingEscrow() external view returns (IOmniVotingEscrow);
    //
    //    /**
    //     * @notice Get timestamp when `user`'s lock finishes.
    //     * @dev The returned value is taken directly from the voting escrow.
    //     */
    //    function getLockedEnd(address user) external view returns (uint256);

    //    /**
    //     * @notice Returns the local user corresponding to an address on a remote chain.
    //     * @dev Returns `address(0)` if the remapping does not exist for the given remote user.
    //     * @param remoteUser - Address of the user on the remote chain which are querying the local address for.
    //     * @param chainId - The chain ID of the network which this user is on.
    //     */
    //    function getLocalUser(address remoteUser, uint256 chainId) external view returns (address);

    /**
     * @notice Returns the remote user corresponding to an address on the local chain.
     * @dev Returns `address(0)` if the remapping does not exist for the given local user.
     * @param localUser - Address of the user on the local chain which are querying the remote address for.
     * @param chainId - The chain ID of the network which the remote user is on.
     */
    function getRemoteUser(address localUser, uint16 chainId) external view returns (address);
}