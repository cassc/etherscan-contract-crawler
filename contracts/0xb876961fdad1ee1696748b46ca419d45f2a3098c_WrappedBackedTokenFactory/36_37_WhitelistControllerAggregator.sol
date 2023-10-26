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

import "./WhitelistController.sol";

/**
 * @dev
 *
 * WhitelistControllerAggregator contract, which is responsible for checking user being whitelisted
 * by any of the registered whitelist controllers.
 * 
 * Due to lack of standardized approach for creating such whitelist registries, each external one
 * should be added via additional adapter contract, which will translate our interface to external one.
 *
 */
contract WhitelistControllerAggregator is OwnableUpgradeable {
    address[] public controllers;

    event AddedController(address indexed controller);
    event RemovedController(address indexed controller);

    constructor() {
        _disableInitializers();
    }
    
    function initialize() external initializer {
        __Ownable_init();
    }

    /**
     * @dev Adds a new controller to registry. Callable only by the controller owner
     *
     * Emits a { AddedController } event
     * 
     * @param controller    Address of whitelist controller to add
     */
    function add(address controller) external onlyOwner {
        controllers.push(controller);
        emit AddedController(controller);
    }

    /**
     * @dev Removes a controller from registry. Callable only by the controller owner.
     * If needed, it first swaps controller at last index and requested one, before removing data at last index.
     *
     * Emits a { RemovedController } event
     * 
     * @param index    Index of the controller to be removed
     */
    function remove(uint256 index) external onlyOwner {
        address removedController = controllers[index];
        if (index != controllers.length - 1)
            controllers[index] = controllers[controllers.length - 1];
        controllers.pop();
        emit RemovedController(removedController);
    }

    /**
     * @dev Checks in all registered controllers, whether given address is marked as whitelisted
     * 
     * @param addressToCheck    Address to be checked
     */
    function isWhitelisted(address addressToCheck) external view returns (bool) {
        for (uint i = 0; i < controllers.length; i++) {
            if (WhitelistController(controllers[i]).isWhitelisted(addressToCheck)) {
                return true;
            }
        }
        return false;
    }
}