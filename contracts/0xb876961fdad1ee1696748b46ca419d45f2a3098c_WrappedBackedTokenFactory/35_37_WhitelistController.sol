/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2021-2023 Backed Finance AG
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @dev
 *
 * Whitelist controller contract, which holds information about whitelisted addresses.
 *
 */
contract WhitelistController is OwnableUpgradeable {
    mapping(address => bool) public isWhitelisted;
    
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __Ownable_init();
    }

    /**
     * @dev Adds set of addresses to the whitelist. Callable only by the controller owner
     *
     * Emits a series of { AddedToWhitelist } event
     * 
     * @param addresses    List of addresses to be marked as whitelisted
     */
    function add(address[] calldata addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            isWhitelisted[addresses[i]] = true;
            emit AddedToWhitelist(addresses[i]);
        }
    }

    /**
     * @dev Removes set of addresses from the whitelist. Callable only by the controller owner
     *
     * Emits a series of { RemovedFromWhitelist } event
     * 
     * @param addresses    List of addresses to be removed from the whitelist
     */
    function remove(address[] calldata addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            isWhitelisted[addresses[i]] = false;
            emit RemovedFromWhitelist(addresses[i]);
        }
    }
}