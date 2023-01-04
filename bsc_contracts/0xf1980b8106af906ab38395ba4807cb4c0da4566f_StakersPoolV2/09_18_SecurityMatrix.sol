/*
    Copyright (C) 2020 InsurAce.io

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.3;

import "./05_18_AddressUpgradeable.sol";
import "./06_18_OwnableUpgradeable.sol";
import "./07_18_PausableUpgradeable.sol";
import "./08_18_ReentrancyGuardUpgradeable.sol";
import "./04_18_SafeMathUpgradeable.sol";
import {ISecurityMatrix} from "./18_18_ISecurityMatrix.sol";

contract SecurityMatrix is ISecurityMatrix, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function initializeSecurityMatrix() public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    // callee -> caller
    mapping(address => mapping(address => uint256)) public allowedCallersMap;
    mapping(address => address[]) public allowedCallersArray;
    address[] public allowedCallees;

    function pauseAll() external onlyOwner whenNotPaused {
        _pause();
    }

    function unPauseAll() external onlyOwner whenPaused {
        _unpause();
    }

    function addAllowdCallersPerCallee(address _callee, address[] memory _callers) external onlyOwner {
        require(_callers.length != 0, "AACPC:1");
        require(allowedCallersArray[_callee].length != 0, "AACPC:2");

        for (uint256 index = 0; index < _callers.length; index++) {
            allowedCallersArray[_callee].push(_callers[index]);
            allowedCallersMap[_callee][_callers[index]] = 1;
        }
    }

    function setAllowdCallersPerCallee(address _callee, address[] memory _callers) external onlyOwner {
        require(_callers.length != 0, "SACPC:1");
        // check if callee exist
        if (allowedCallersArray[_callee].length == 0) {
            // not exist, so add callee
            allowedCallees.push(_callee);
        } else {
            // if callee exist, then purge data
            for (uint256 i = 0; i < allowedCallersArray[_callee].length; i++) {
                delete allowedCallersMap[_callee][allowedCallersArray[_callee][i]];
            }
            delete allowedCallersArray[_callee];
        }
        // and overwrite
        for (uint256 index = 0; index < _callers.length; index++) {
            allowedCallersArray[_callee].push(_callers[index]);
            allowedCallersMap[_callee][_callers[index]] = 1;
        }
    }

    function isAllowdCaller(address _callee, address _caller) external view override whenNotPaused returns (bool) {
        return allowedCallersMap[_callee][_caller] == 1 ? true : false;
    }

    function getAllowedCallees() external view returns (address[] memory) {
        return allowedCallees;
    }

    function getAllowedCallersPerCallee(address _callee) external view returns (address[] memory) {
        return allowedCallersArray[_callee];
    }
}