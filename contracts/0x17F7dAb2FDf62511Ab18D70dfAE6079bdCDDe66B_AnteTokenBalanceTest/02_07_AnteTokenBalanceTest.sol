// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import {AnteTest} from "../AnteTest.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Checks that [HOLDER] holds at least [THRESHOLD] [TOKEN]s
/// @notice Ante Test to check if a holder's balance gets below specified threshold
/// Passing a address(0) as token will check for native token balance
contract AnteTokenBalanceTest is
    AnteTest("[HOLDER] [TOKEN] balance remains >= [THRESHOLD]")
{
    address public factory;
    address public tokenHolder;
    IERC20 public token;
    uint256 public thresholdBalance;

    constructor(
        address _tokenAddress,
        address _holderAddress,
        uint256 _thresholdBalance,
        address _testAuthor
    ) {
        factory = msg.sender;
        token = IERC20(_tokenAddress);
        tokenHolder = _holderAddress;
        thresholdBalance = _thresholdBalance;

        if (_tokenAddress == address(0)) {
            protocolName = "ETH";
        } else {
            try IERC20Metadata(_tokenAddress).name() returns (
                string memory name
            ) {
                protocolName = name;
            } catch {}

            bytes memory bProtocolName = bytes(protocolName);
            if (bProtocolName.length == 0) {
                try IERC20Metadata(_tokenAddress).symbol() returns (
                    string memory symbol
                ) {
                    protocolName = symbol;
                } catch {
                    protocolName = "TOKEN";
                }
            }
        }

        testedContracts = [_tokenAddress];
        testAuthor = _testAuthor;
    }

    /// @notice test to check if [HOLDER] owns >= [THRESHOLD] [TOKEN]s
    /// @return true if [TOKEN] balance of [HOLDER] is >= [THRESHOLD]
    function checkTestPasses() public view override returns (bool) {
        if (address(token) == address(0)) {
            return (address(token).balance >= thresholdBalance);
        }

        return (token.balanceOf(tokenHolder) >= thresholdBalance);
    }
}