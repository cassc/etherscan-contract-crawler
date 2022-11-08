// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import {AnteTest} from "../AnteTest.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title Checks Dai balance in Compound cDai remains >= 100M
/// @notice Ante Test to check
contract AnteDaiCompoundcDaiAbove100MTest is AnteTest("Compound cDai Dai balance remains >= 100M") {
    address public constant TARGET_ADDRESS = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;

    IERC20Metadata public constant TOKEN = IERC20Metadata(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    // Will be set to desired token balance threshold
    uint256 public immutable thresholdBalance;

    constructor() {
        thresholdBalance = 100_000_000 * (10**TOKEN.decimals());

        protocolName = "dai";

        testedContracts = [address(TOKEN), TARGET_ADDRESS];
    }

    /// @notice test to check if $[TOKEN] balance in [TARGET] is >= [THRESHOLD]
    /// @return true if $[TOKEN] balance in [TARGET] is >= [THRESHOLD]
    function checkTestPasses() public view override returns (bool) {
        return (TOKEN.balanceOf(TARGET_ADDRESS) >= thresholdBalance);
    }
}