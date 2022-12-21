// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

/*

░██╗░░░░░░░██╗░█████╗░░█████╗░░░░░░░███████╗██╗
░██║░░██╗░░██║██╔══██╗██╔══██╗░░░░░░██╔════╝██║
░╚██╗████╗██╔╝██║░░██║██║░░██║█████╗█████╗░░██║
░░████╔═████║░██║░░██║██║░░██║╚════╝██╔══╝░░██║
░░╚██╔╝░╚██╔╝░╚█████╔╝╚█████╔╝░░░░░░██║░░░░░██║
░░░╚═╝░░░╚═╝░░░╚════╝░░╚════╝░░░░░░░╚═╝░░░░░╚═╝

*
* MIT License
* ===========
*
* Copyright (c) 2020 WooTrade
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/// @title Rebate manager interface for WooFi Swap.
/// @notice this is for swap rebate or potential incentive program

interface IWooRebateManager {
    event Withdraw(address indexed token, address indexed to, uint256 amount);
    event RebateRateUpdated(address indexed brokerAddr, uint256 rate);
    event ClaimReward(address indexed brokerAddr, uint256 amount);

    /// @dev Gets the rebate rate for the given broker.
    /// Note: decimal: 18;  1e16 = 1%, 1e15 = 0.1%, 1e14 = 0.01%
    /// @param brokerAddr the address for rebate
    /// @return The rebate rate (decimal: 18; 1e16 = 1%, 1e15 = 0.1%, 1e14 = 0.01%)
    function rebateRate(address brokerAddr) external view returns (uint256);

    /// @dev set the rebate rate
    /// @param brokerAddr the rebate address
    /// @param rate the rebate rate
    function setRebateRate(address brokerAddr, uint256 rate) external;

    /// @dev adds the pending reward for the given user.
    /// @param brokerAddr the address for rebate
    /// @param amountInUSD the pending reward amount
    function addRebate(address brokerAddr, uint256 amountInUSD) external;

    /// @dev Pending amount in reward token (e.g. $woo).
    /// @param brokerAddr the address for rebate
    function pendingRebateInReward(address brokerAddr) external view returns (uint256);

    /// @dev Pending amount in quote token (e.g. usdc).
    /// @param brokerAddr the address for rebate
    function pendingRebateInQuote(address brokerAddr) external view returns (uint256);

    /// @dev Claims the reward ($woo token will be distributed)
    function claimRebate() external;

    /// @dev get the quote token address
    /// @return address of quote token
    function quoteToken() external view returns (address);
}