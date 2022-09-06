// SPDX-License-Identifier: AGPL-3.0-or-later

// token.sol -- I frobbed an inc and all I got was this lousy token

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

import {DSSLike} from "dss/dss.sol";
import {DSNote} from "ds-note/note.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {Render, DataURI} from "./render.sol";

interface SumLike {
    function incs(address)
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256);
}

interface CTRLike {
    function balanceOf(address) external view returns (uint256);
    function push(address, uint256) external;
}

struct Inc {
    address guy;
    uint256 net;
    uint256 tab;
    uint256 tax;
    uint256 num;
    uint256 hop;
}

contract DSSToken is ERC721, DSNote {
    using FixedPointMathLib for uint256;
    using DataURI for string;

    error WrongPayment(uint256 sent, uint256 cost);
    error Forbidden();
    error PullFailed();

    uint256 constant WAD        = 1    ether;
    uint256 constant BASE_PRICE = 0.01 ether;
    uint256 constant INCREASE   = 1.1  ether;

    DSSLike public immutable dss;   // DSS module
    DSSLike public immutable coins; // Token ID counter
    DSSLike public immutable price; // Token price counter
    CTRLike public immutable ctr;   // CTR token

    address public owner;

    modifier auth() {
        if (msg.sender != owner) revert Forbidden();
        _;
    }

    modifier owns(uint256 tokenId) {
        if (msg.sender != ownerOf(tokenId)) revert Forbidden();
        _;
    }

    modifier exists(uint256 tokenId) {
        ownerOf(tokenId);
        _;
    }

    constructor(address _dss, address _ctr) ERC721("CounterDAO", "++") {
        owner = msg.sender;

        dss = DSSLike(_dss);
        ctr = CTRLike(_ctr);

        // Build a counter to track token IDs.
        coins = DSSLike(dss.build("coins", address(0)));

        // Build a counter to track token price.
        price = DSSLike(dss.build("price", address(0)));

        // Authorize core dss modules.
        coins.bless();
        price.bless();

        // Initialize counters.
        coins.use();
        price.use();
    }

    /// @notice Mint a dss-token to caller. Must send ether equal to
    /// current `cost`. Distributes 100 CTR to caller if a sufficient
    /// balance is available in the contract.
    function mint() external payable note {
        uint256 _cost = cost();
        if (msg.value != _cost) {
            revert WrongPayment(msg.value, _cost);
        }

        // Increment token ID.
        coins.hit();
        uint256 id = coins.see();

        // Build and initialize a counter associated with this token.
        DSSLike _count = DSSLike(dss.build(bytes32(id), address(0)));
        _count.bless();
        _count.use();

        // Distribute 100 CTR to caller.
        _give(msg.sender, 100 * WAD);
        _safeMint(msg.sender, id);
    }

    /// @notice Increase `cost` by 10%. Distributes 10 CTR to caller
    /// if a sufficient balance is available in the contract.
    function hike() external note {
        if (price.see() < 100) {
            // Increment price counter.
            price.hit();
            _give(msg.sender, 10 * WAD);
        }
    }

    /// @notice Decrease `cost` by 10%. Distributes 10 CTR to caller
    /// if a sufficient balance is available in the contract.
    function drop() external note {
        if (price.see() > 0) {
            // Decrement price counter.
            price.dip();
            _give(msg.sender, 10 * WAD);
        }
    }

    /// @notice Get cost to `mint` a dss-token.
    /// @return Current `mint` price in wei.
    function cost() public view returns (uint256) {
        return cost(price.see());
    }

    /// @notice Get cost to `mint` a dss-token for a given value
    /// of the `price` counter.
    /// @param net Value of the `price` counter.
    /// @return `mint` price in wei.
    function cost(uint256 net) public pure returns (uint256) {
        // Calculate cost to mint based on price counter value.
        // Price increases by 10% for each counter increment, i.e.:
        //
        // cost = 0.01 ether * 1.01 ether ^ (counter value)

        return BASE_PRICE.mulWadUp(INCREASE.rpow(net, WAD));
    }

    /// @notice Increment a token's counter. Only token owner.
    /// @param tokenId dss-token ID.
    function hit(uint256 tokenId) external owns(tokenId) note {
        count(tokenId).hit();
    }

    /// @notice Decrement a token's counter. Only token owner.
    /// @param tokenId dss-token ID
    function dip(uint256 tokenId) external owns(tokenId) note {
        count(tokenId).dip();
    }

    /// @notice Withdraw ether balance from contract. Only contract owner.
    /// @param dst Destination address.
    function pull(address dst) external auth note {
        (bool ok,) = payable(dst).call{ value: address(this).balance }("");
        if (!ok) revert PullFailed();
    }

    /// @notice Change contract owner. Only contract owner.
    /// @param guy New contract owner.
    function swap(address guy) external auth note {
        owner = guy;
    }

    /// @notice Read a token's counter value.
    /// @param tokenId dss-token ID.
    function see(uint256 tokenId) external view returns (uint256) {
        return count(tokenId).see();
    }

    /// @notice Get the DSSProxy for a token's counter.
    /// @param tokenId dss-token ID.
    function count(uint256 tokenId) public view returns (DSSLike) {
        // dss.scry returns the deterministic address of a DSSProxy contract for
        // a given deployer, salt, and owner. Since we know these values, we
        // don't need to write the counter address to storage.
        return DSSLike(dss.scry(address(this), bytes32(tokenId), address(0)));
    }

    /// @notice Get the Inc for a DSSProxy address.
    /// @param guy DSSProxy address.
    function inc(address guy) public view returns (Inc memory) {
        // Get low level counter information from the Sum.
        SumLike sum = SumLike(dss.sum());
        (uint256 net, uint256 tab, uint256 tax, uint256 num, uint256 hop) =
            sum.incs(guy);
        return Inc(guy, net, tab, tax, num, hop);
    }

    /// @notice Get URI for a dss-token.
    /// @param tokenId dss-token ID.
    /// @return base64 encoded Data URI string.
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        exists(tokenId)
        returns (string memory)
    {
        return tokenJSON(tokenId).toDataURI("application/json");
    }

    /// @notice Get JSON metadata for a dss-token.
    /// @param tokenId dss-token ID.
    /// @return JSON metadata string.
    function tokenJSON(uint256 tokenId)
        public
        view
        exists(tokenId)
        returns (string memory)
    {
        Inc memory countInc = inc(address(count(tokenId)));
        return Render.json(tokenId, tokenSVG(tokenId).toDataURI("image/svg+xml"), countInc);
    }

    /// @notice Get SVG image for a dss-token.
    /// @param tokenId dss-token ID.
    /// @return SVG image string.
    function tokenSVG(uint256 tokenId)
        public
        view
        exists(tokenId)
        returns (string memory)
    {
        Inc memory countInc = inc(address(count(tokenId)));
        Inc memory priceInc = inc(address(price));
        return Render.image(tokenId, coins.see(), countInc, priceInc);
    }

    function _give(address dst, uint256 wad) internal {
        if (ctr.balanceOf(address(this)) >= wad) ctr.push(dst, wad);
    }
}