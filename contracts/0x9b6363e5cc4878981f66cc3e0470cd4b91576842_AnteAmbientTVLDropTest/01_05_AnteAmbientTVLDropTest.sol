// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import {AnteTest} from "../AnteTest.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title AnteAmbientTVLDropTest
/// @notice Ante Test that fails if either ETH or USDC balance in Ambient drop -90% from values as of this Ante Test deployment
contract AnteAmbientTVLDropTest is AnteTest("ETH and USDC individual balances in Ambient do NOT drop -90% from this Ante Test deployment") {

    // https://etherscan.io/address/0xAaAaAAAaA24eEeb8d57D431224f73832bC34f688
    address public constant ambientSwapDexAddr = 0xAaAaAAAaA24eEeb8d57D431224f73832bC34f688;
    IERC20Metadata public constant usdcToken = IERC20Metadata(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    uint256 public immutable thresholdEth;
    uint256 public immutable thresholdUsdc;

    constructor() {
        protocolName = "Ambient";
        thresholdEth = ambientSwapDexAddr.balance;
        thresholdUsdc = usdcToken.balanceOf(ambientSwapDexAddr);
        testedContracts = [ambientSwapDexAddr];
    }

    /// @notice test to check balance of ETH and USDC in Ambient Finance
    /// @return true if both ETH and USDC in Ambient's Swap Dex remains above 10% as of the deployment amount
    function checkTestPasses() public view override returns (bool) {
        return (
             !(ambientSwapDexAddr.balance < thresholdEth / 10 &&
            usdcToken.balanceOf(ambientSwapDexAddr) < thresholdUsdc / 10)
        );
    }
}