/*
 * Origin Protocol
 * https://originprotocol.com
 *
 * Released under the MIT license
 * SPDX-License-Identifier: MIT
 * https://github.com/OriginProtocol/nft-launchpad
 *
 * Copyright 2022 Origin Protocol, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity ^0.8.4;

interface ISeason {
    function claimEndTime() external view returns (uint256);

    function lockStartTime() external view returns (uint256);

    function endTime() external view returns (uint256);

    function startTime() external view returns (uint256);

    function getTotalPoints() external view returns (uint128);

    function getPoints(address userAddress) external view returns (uint128);

    function expectedRewards(address userAddress)
        external
        view
        returns (uint256, uint256);

    function pointsInTime(uint256 amount, uint256 blockStamp)
        external
        view
        returns (uint128);

    function claim(address userAddress) external returns (uint256, uint256);

    function stake(address userAddress, uint256 amount)
        external
        returns (uint128);

    function unstake(address userAddress) external returns (uint256, uint256);

    function bootstrap(uint256 initialSupply) external;
}