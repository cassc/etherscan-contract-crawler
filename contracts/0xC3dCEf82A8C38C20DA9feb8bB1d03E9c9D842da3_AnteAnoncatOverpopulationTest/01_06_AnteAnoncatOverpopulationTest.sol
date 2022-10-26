// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import {AnteTest} from "../AnteTest.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/// @title Checks that total supply of Anoncats does not exceed 100
/// @author abitwhaleish.eth (0x1A2B73207C883Ce8E51653d6A9cC8a022740cCA4)
/// @notice Ante Test to check if the total supply of Anoncats exceeds 100
contract AnteAnoncatOverpopulationTest is AnteTest("No more than 100 Anoncats exist") {
    // https://etherscan.io/address/0xe7141C205a7a74241551dAF007537A041867e0B0
    IERC721Enumerable public constant ANONCATS = IERC721Enumerable(0xe7141C205a7a74241551dAF007537A041867e0B0);
    uint256 public immutable MAX_SUPPLY = 100;

    constructor() {
        protocolName = "Anoncats";
        testedContracts = [address(ANONCATS)];
    }

    /// @notice test to check if total supply of Anoncats is <= 100
    /// @return true if total supply of Anoncats is <= 100
    function checkTestPasses() public view override returns (bool) {
        return (ANONCATS.totalSupply() <= MAX_SUPPLY);
    }
}