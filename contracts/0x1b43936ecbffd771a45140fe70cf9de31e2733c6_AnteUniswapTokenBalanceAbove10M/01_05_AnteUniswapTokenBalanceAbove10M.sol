// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import {AnteTest} from "../AnteTest.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title Checks $UNI balance in Uniswap Treasury remains >= 10M
/// @notice Ante Test to check if $UNI balance in Uniswap Treasury is >10M
contract AnteUniswapTokenBalanceAbove10M is AnteTest("Uniswap Treasury balance remains >= 10M") {
    // https://etherscan.io/address/0x1a9C8182C09F50C8318d769245beA52c32BE35BC
    address public constant HOLDER_ADDRESS = 0x1a9C8182C09F50C8318d769245beA52c32BE35BC;

    // https://etherscan.io/address/0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984
    IERC20Metadata public constant TOKEN = IERC20Metadata(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);

    // Will be set to desired token balance threshold
    uint256 public immutable thresholdBalance;

    constructor() {
        thresholdBalance = (10000000) * (10**TOKEN.decimals());

        protocolName = "Uniswap";

        testedContracts = [address(TOKEN), HOLDER_ADDRESS];
    }

    /// @notice test to check if $UNI balance in Uniswap Treasury is >10M
    /// @return true if $UNI balance in Uniswap Treasury is >10M
    function checkTestPasses() public view override returns (bool) {
        return (TOKEN.balanceOf(HOLDER_ADDRESS) >= thresholdBalance);
    }
}