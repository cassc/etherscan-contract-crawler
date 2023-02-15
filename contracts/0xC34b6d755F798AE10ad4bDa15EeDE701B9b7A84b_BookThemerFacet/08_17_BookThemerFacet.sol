//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "hardhat/console.sol";
import "solady/src/utils/LibPRNG.sol";
import "solady/src/utils/DynamicBufferLib.sol";
import "solady/src/utils/LibString.sol";
import "solady/src/utils/LibSort.sol";

import "hardhat-deploy/solc_0.8/diamond/UsingDiamondOwner.sol";

import "./LibStorage.sol";

import { EnumerableSet } from '@solidstate/contracts/data/EnumerableSet.sol';

import {BookInternalFacet} from "./BookInternalFacet.sol";

contract BookThemerFacet is UsingDiamondOwner, WithStorage, BookInternalFacet {
    using LibString for *;
    using LibSort for *;
    using LibPRNG for LibPRNG.PRNG;
    using EnumerableSet for EnumerableSet.UintSet;

    event ThemeUpdated(ThemeInfo newTheme);
    
    function getCurrentTheme() public view returns (ThemeInfo memory) {
        return ThemeInfo({
            allowedAttributes: getAllowedAttributes(),
            allowedAttributeCounts: getAllowedAttributeCounts(),
            activatedAt: currentTheme().activatedAt,
            duration: currentTheme().duration
        });
    }
    
    function setCurrentTheme(
        uint8[][10] calldata _allowedAttributes,
        uint8[] calldata _allowedAttributeCounts,
        uint64 activatedAt,
        uint64 duration
    ) public onlyRole(ADMIN) {
        bk().currentThemeVersion++;
        
        for (uint8 i; i < _allowedAttributes.length; ++i) {
            for (uint8 j; j < _allowedAttributes[i].length; ++j) {
                currentTheme().allowedAttributes[i].add(_allowedAttributes[i][j]);
            }
        }
                
        for (uint8 i; i < _allowedAttributeCounts.length; ++i) {
            currentTheme().allowedAttributeCounts.add(_allowedAttributeCounts[i]);
        }

        currentTheme().activatedAt = (activatedAt == 0) ? uint64(block.timestamp) : activatedAt;
        currentTheme().duration = duration;
        
        emit ThemeUpdated(getCurrentTheme());
    }
    
    function punkConformsToTheme(uint80 assets) external view returns (bool) {
        return _punkConformsToTheme(assets);
    }
    
    function punkAdheresToAllowedAttributes(
        uint80 assets
    ) external view returns (bool) {
        return _punkAdheresToAllowedAttributes(assets);
    }
}