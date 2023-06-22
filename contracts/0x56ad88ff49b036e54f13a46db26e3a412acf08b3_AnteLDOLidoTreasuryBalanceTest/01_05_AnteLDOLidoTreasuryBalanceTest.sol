// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import {AnteTest} from "../AnteTest.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";


/// @title Checks $LDO balance in Lido Treasury remains >= 10M
/// @author Put your ETH address here
/// @notice Ante Test to check
contract AnteLDOLidoTreasuryBalanceTest is AnteTest("Lido Treasury holds >= 10M LDO") {
    // https://etherscan.io/address/0x3e40D73EB977Dc6a537aF587D48316feE66E9C8c
    address public constant HOLDER_ADDRESS = 0x3e40D73EB977Dc6a537aF587D48316feE66E9C8c;

    // https://etherscan.io/address/0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32
    IERC20Metadata public constant TOKEN = IERC20Metadata(0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32);

    // Will be set to desired token balance threshold
    uint256 public immutable thresholdBalance;

    constructor() {
        thresholdBalance = (10 * 1000 * 1000) * (10**TOKEN.decimals());

        protocolName = "Lido";

        testedContracts = [address(TOKEN), HOLDER_ADDRESS];
    }

    /// @notice test to check if $LDO balance in Lido Treasury is >= 10M
    /// @return true if $LDO balance in Lido Treasury is >= 10M
    function checkTestPasses() public view override returns (bool) {
        return (TOKEN.balanceOf(HOLDER_ADDRESS) >= thresholdBalance);
    }
}