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
* Copyright (c) 2022 WooTrade
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

/// @title Contract to collect transaction fee of Woo private pool.
interface IWooFeeManager {
    /* ----- Events ----- */

    event FeeRateUpdated(address indexed token, uint256 newFeeRate);
    event Withdraw(address indexed token, address indexed to, uint256 amount);

    /* ----- External Functions ----- */

    /// @dev fee rate for the given base token:
    /// NOTE: fee rate decimal 18: 1e16 = 1%, 1e15 = 0.1%, 1e14 = 0.01%
    /// @param token the base token
    /// @return the fee rate
    function feeRate(address token) external view returns (uint256);

    /// @dev Sets the fee rate for the given token
    /// @param token the base token
    /// @param newFeeRate the new fee rate
    function setFeeRate(address token, uint256 newFeeRate) external;

    /// @dev Collects the swap fee to the given brokder address.
    /// @param amount the swap fee amount
    /// @param brokerAddr the broker address to rebate to
    function collectFee(uint256 amount, address brokerAddr) external;

    /// @dev get the quote token address
    /// @return address of quote token
    function quoteToken() external view returns (address);

    /// @dev Collects the fee and distribute to rebate and vault managers.
    function distributeFees() external;

    /// @dev Add the rebate amounts for the specified broker addresses.
    /// @param brokerAddrs the broker address for rebate
    /// @param amounts the rebate amount for each broker address
    function addRebates(address[] memory brokerAddrs, uint256[] memory amounts) external;
}