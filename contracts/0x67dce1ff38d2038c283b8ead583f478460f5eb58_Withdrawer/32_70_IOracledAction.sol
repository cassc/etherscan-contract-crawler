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

pragma solidity >=0.8.0;

import './IBaseAction.sol';

/**
 * @dev Oracled action interface
 */
interface IOracledAction is IBaseAction {
    /**
     * @dev Feed data
     * @param base Token to rate
     * @param quote Token used for the price rate
     * @param rate Price of a token (base) expressed in `quote`. It must use the corresponding number of decimals so
     *             that when performing a fixed point product of it by a `base` amount, the result is expressed in
     *             `quote` decimals. For example, if `base` is ETH and `quote` is USDC, the number of decimals of `rate`
     *             must be 6: FixedPoint.mul(X[ETH], rate[USDC/ETH]) = FixedPoint.mul(X[18], price[6]) = X * price [6].
     * @param deadline Expiration timestamp until when the given quote is considered valid
     */
    struct FeedData {
        address base;
        address quote;
        uint256 rate;
        uint256 deadline;
    }

    /**
     * @dev Emitted every time an oracle signer is allowed
     */
    event OracleSignerAllowed(address indexed signer);

    /**
     * @dev Emitted every time an oracle signer is disallowed
     */
    event OracleSignerDisallowed(address indexed signer);

    /**
     * @dev Tells the list of oracle signers
     */
    function getOracleSigners() external view returns (address[] memory);

    /**
     * @dev Tells whether an address is as an oracle signer or not
     * @param signer Address of the signer being queried
     */
    function isOracleSigner(address signer) external view returns (bool);

    /**
     * @dev Hashes the list of feeds
     * @param feeds List of feeds to be hashed
     */
    function getFeedsDigest(FeedData[] memory feeds) external pure returns (bytes32);

    /**
     * @dev Updates the list of allowed oracle signers
     * @param toAdd List of signers to be added to the oracle signers list
     * @param toRemove List of signers to be removed from the oracle signers list
     */
    function setOracleSigners(address[] memory toAdd, address[] memory toRemove) external;
}