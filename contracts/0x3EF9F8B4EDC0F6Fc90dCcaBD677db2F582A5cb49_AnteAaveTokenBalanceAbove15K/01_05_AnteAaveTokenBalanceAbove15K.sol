// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import {AnteTest} from "../AnteTest.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title Checks AAVE balance in Aave Ecosystem Reserve remains >= 15k
/// @notice Ante Test to check
contract AnteAaveTokenBalanceAbove15K is AnteTest("Aave Ecosystem Reserve Aave balance remains >= 15k") {
    // https://etherscan.io/address/0x25F2226B597E8F9514B3F68F00f494cF4f286491
    address public constant HOLDER_ADDRESS = 0x25F2226B597E8F9514B3F68F00f494cF4f286491;

    // https://etherscan.io/address/0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9
    IERC20Metadata public constant TOKEN = IERC20Metadata(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);

    // Will be set to desired token balance threshold
    uint256 public immutable thresholdBalance;

    constructor() {
        thresholdBalance = (15000) * (10**TOKEN.decimals());

        protocolName = "Aave";

        testedContracts = [address(TOKEN), HOLDER_ADDRESS];
    }

    /// @notice test to check if AAVE balance in Aave Ecosystem Reserve is >= 15k
    /// @return true if AAVE balance in Aave Ecosystem Reserve is >= 15k
    function checkTestPasses() public view override returns (bool) {
        return (TOKEN.balanceOf(HOLDER_ADDRESS) >= thresholdBalance);
    }
}