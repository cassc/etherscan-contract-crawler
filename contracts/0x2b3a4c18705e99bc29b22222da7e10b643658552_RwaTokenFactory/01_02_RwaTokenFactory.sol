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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

import {RwaToken} from "./RwaToken.sol";

/**
 * @author Nazar Duchak <[email protected]>
 * @title A Factory for RWA Tokens.
 */
contract RwaTokenFactory {
    uint256 internal constant WAD = 10**18;

    /**
     * @notice RWA Token created.
     * @param name Token name.
     * @param symbol Token symbol.
     * @param recipient Token address recipient.
     */
    event RwaTokenCreated(address indexed token, string name, string indexed symbol, address indexed recipient);

    /**
     * @notice Deploy an RWA Token and mint `1 * WAD` to recipient address.
     * @param name Token name.
     * @param symbol Token symbol.
     * @param recipient Recipient address.
     */
    function createRwaToken(
        string calldata name,
        string calldata symbol,
        address recipient
    ) public returns (RwaToken) {
        require(bytes(name).length != 0, "RwaTokenFactory/name-not-set");
        require(bytes(symbol).length != 0, "RwaTokenFactory/symbol-not-set");
        require(recipient != address(0), "RwaTokenFactory/invalid-recipient");

        RwaToken token = new RwaToken(name, symbol);
        token.transfer(recipient, 1 * WAD);

        emit RwaTokenCreated(address(token), name, symbol, recipient);
        return token;
    }
}