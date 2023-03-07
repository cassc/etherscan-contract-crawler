// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import {AnteTest} from "../AnteTest.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title Checks USDT balance in Tether Treasury remains >= 20M
/// @author 0xf3486f2ac4efF4C5465a8C637c4A46E96cBb4427
/// @notice Ante Test to check
contract AnteUSDTBalanceTest is AnteTest("Tether Treasury USDT balance remains >= 20M") {
    // https://etherscan.io/address/0x5754284f345afc66a98fbB0a0Afe71e0F007B949
    address public constant HOLDER_ADDRESS = 0x5754284f345afc66a98fbB0a0Afe71e0F007B949;

    // https://etherscan.io/address/0xdac17f958d2ee523a2206206994597c13d831ec7
    IERC20Metadata public constant TOKEN = IERC20Metadata(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    // Will be set to desired token balance threshold
    uint256 public immutable thresholdBalance;

    constructor() {
        thresholdBalance = (20_000_000) * (10**TOKEN.decimals());

        protocolName = "Tether";

        testedContracts = [address(TOKEN), HOLDER_ADDRESS];
    }

    /// @notice test to check if USDT balance in Tether Treasury is >= 20M
    /// @return true if USDT balance in Tether Treasury is >= 20M
    function checkTestPasses() public view override returns (bool) {
        return (TOKEN.balanceOf(HOLDER_ADDRESS) >= thresholdBalance);
    }
}