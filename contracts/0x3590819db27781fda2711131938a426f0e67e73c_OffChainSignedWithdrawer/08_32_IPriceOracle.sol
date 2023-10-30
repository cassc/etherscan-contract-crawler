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

import '@mimic-fi/v3-authorizer/contracts/interfaces/IAuthorized.sol';

/**
 * @title IPriceOracle
 * @dev Price oracle interface
 *
 * Tells the price of a token (base) in a given quote based the following rule: the response is expressed using the
 * corresponding number of decimals so that when performing a fixed point product of it by a `base` amount it results
 * in a value expressed in `quote` decimals. For example, if `base` is ETH and `quote` is USDC, then the returned
 * value is expected to be expressed using 6 decimals:
 *
 * FixedPoint.mul(X[ETH], price[USDC/ETH]) = FixedPoint.mul(X[18], price[6]) = X * price [6]
 */
interface IPriceOracle is IAuthorized {
    /**
     * @dev Price data
     * @param base Token to rate
     * @param quote Token used for the price rate
     * @param rate Price of a token (base) expressed in `quote`
     * @param deadline Expiration timestamp until when the given quote is considered valid
     */
    struct PriceData {
        address base;
        address quote;
        uint256 rate;
        uint256 deadline;
    }

    /**
     * @dev The signer is not allowed
     */
    error PriceOracleInvalidSigner(address signer);

    /**
     * @dev The feed for the given (base, quote) pair doesn't exist
     */
    error PriceOracleMissingFeed(address base, address quote);

    /**
     * @dev The price deadline is in the past
     */
    error PriceOracleOutdatedPrice(address base, address quote, uint256 deadline, uint256 currentTimestamp);

    /**
     * @dev The base decimals are bigger than the quote decimals plus the fixed point decimals
     */
    error PriceOracleBaseDecimalsTooBig(address base, uint256 baseDecimals, address quote, uint256 quoteDecimals);

    /**
     * @dev The inverse feed decimals are bigger than the maximum inverse feed decimals
     */
    error PriceOracleInverseFeedDecimalsTooBig(address inverseFeed, uint256 inverseFeedDecimals);

    /**
     * @dev The quote feed decimals are bigger than the base feed decimals plus the fixed point decimals
     */
    error PriceOracleQuoteFeedDecimalsTooBig(uint256 quoteFeedDecimals, uint256 baseFeedDecimals);

    /**
     * @dev Emitted every time a signer is changed
     */
    event SignerSet(address indexed signer, bool allowed);

    /**
     * @dev Emitted every time a feed is set for (base, quote) pair
     */
    event FeedSet(address indexed base, address indexed quote, address feed);

    /**
     * @dev Tells whether an address is as an allowed signer or not
     * @param signer Address of the signer being queried
     */
    function isSignerAllowed(address signer) external view returns (bool);

    /**
     * @dev Tells the list of allowed signers
     */
    function getAllowedSigners() external view returns (address[] memory);

    /**
     * @dev Tells the digest expected to be signed by the off-chain oracle signers for a list of prices
     * @param prices List of prices to be signed
     */
    function getPricesDigest(PriceData[] memory prices) external view returns (bytes32);

    /**
     * @dev Tells the price of a token `base` expressed in a token `quote`
     * @param base Token to rate
     * @param quote Token used for the price rate
     */
    function getPrice(address base, address quote) external view returns (uint256);

    /**
     * @dev Tells the price of a token `base` expressed in a token `quote`
     * @param base Token to rate
     * @param quote Token used for the price rate
     * @param data Encoded data to validate in order to compute the requested rate
     */
    function getPrice(address base, address quote, bytes memory data) external view returns (uint256);

    /**
     * @dev Tells the feed address for (base, quote) pair. It returns the zero address if there is no one set.
     * @param base Token to be rated
     * @param quote Token used for the price rate
     */
    function getFeed(address base, address quote) external view returns (address);

    /**
     * @dev Sets a signer condition
     * @param signer Address of the signer to be set
     * @param allowed Whether the requested signer is allowed
     */
    function setSigner(address signer, bool allowed) external;

    /**
     * @dev Sets a feed for a (base, quote) pair
     * @param base Token base to be set
     * @param quote Token quote to be set
     * @param feed Feed to be set
     */
    function setFeed(address base, address quote, address feed) external;
}