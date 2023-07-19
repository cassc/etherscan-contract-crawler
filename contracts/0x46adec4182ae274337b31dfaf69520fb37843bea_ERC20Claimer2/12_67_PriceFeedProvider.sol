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

import '@mimic-fi/v2-helpers/contracts/math/UncheckedMath.sol';

import './IPriceFeedProvider.sol';

/**
 * @title IPriceFeedProvider
 * @dev Contract providing price feed references for (base, quote) token pairs
 */
contract PriceFeedProvider is IPriceFeedProvider {
    using UncheckedMath for uint256;

    // Mapping of price feeds from "token A" to "token B"
    mapping (address => mapping (address => address)) private _priceFeeds;

    /**
     * @dev Tells the price feed address for (base, quote) pair. It returns the zero address if there is no one set.
     * @param base Token to be rated
     * @param quote Token used for the price rate
     */
    function getPriceFeed(address base, address quote) external view override returns (address) {
        return _priceFeeds[base][quote];
    }

    /**
     * @dev Sets a of price feed
     * @param base Token base to be set
     * @param quote Token quote to be set
     * @param feed Price feed to be set
     */
    function setPriceFeed(address base, address quote, address feed) public virtual override {
        _priceFeeds[base][quote] = feed;
        emit PriceFeedSet(base, quote, feed);
    }

    /**
     * @dev Sets a list of price feeds. Sender must be authorized.
     * @param bases List of token bases to be set
     * @param quotes List of token quotes to be set
     * @param feeds List of price feeds to be set
     */
    function setPriceFeeds(address[] memory bases, address[] memory quotes, address[] memory feeds)
        public
        virtual
        override
    {
        require(bases.length == quotes.length, 'SET_FEEDS_INVALID_QUOTES_LENGTH');
        require(bases.length == feeds.length, 'SET_FEEDS_INVALID_FEEDS_LENGTH');
        for (uint256 i = 0; i < bases.length; i = i.uncheckedAdd(1)) setPriceFeed(bases[i], quotes[i], feeds[i]);
    }
}