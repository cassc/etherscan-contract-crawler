// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/*
 _____ _         _____               
|     |_|___ ___|   __|_ _ _ ___ ___ 
| | | | |   | . |__   | | | | .'| . |
|_|_|_|_|_|_|___|_____|_____|__,|  _|
                                |_| 
*
* MIT License
* ===========
*
* Copyright (c) 2022 MinoSwap
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
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE

*/

interface IMinoDistributor {

    /* ========== VIEWS ========== */
    function uniRouterAddress() external returns (address);

    function devShare() external returns (uint256);

    function devAddress() external returns (address);

    function govShare() external returns (uint256);

    function govAddress() external returns (address);

    function harvestShare() external returns (uint256);

    function supporterShare() external returns (uint256);

    // Slippage factor for swaps
    function slippageFactor() external returns (uint256);

    function distributees(uint256 _pid) external view returns (address distributeeAddress, address token, uint256 share, uint256 accReward);

    function nftStakingAddress() external returns (address);

    function minoSupporterReward() external returns (uint256);

    function minoStakingReward() external returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function harvest() external;

    /* ========== RESTRICTED FUNCTIONS ========== */

    function withdrawReward(uint256 _pid) external returns (uint256);

    function updateSlippageFactor(uint256 _slippageFactor) external;
}