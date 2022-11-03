// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma abicoder v2;

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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVestingMaster {

    /* ========== STRUCTS ========== */

    // Info of each user's vesting.
    struct LockedReward {
        uint256 vesting; // How much is being vested in total
        uint256 pending; // Rewards yet to be claimed (vesting - amount_claimed)
        uint256 start; // Start of the vesting period
        uint256 lastClaimed; // Last time the vested amount was claimed
    }
    
    /* ========== EVENTS ========== */

    event Lock(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event AddFarm(address indexed user, address farmAddress);
    event RemoveFarm(address indexed user, address farmAddress);
    event SetDevAddress(address indexed user, address devAddress);

    /* ========== RESTRICTED FUNCTIONS ========== */

    function lock(address, uint256) external;
    function addFarm(address) external;
    function removeFarm(address) external;
    function setDevAddress(address) external;

    /* ========== MUTATIVE FUNCTIONS ========== */

    function claim() external;

    /* ========== VIEWS ========== */

    function vestingToken() external view returns (IERC20);

    function period() external view returns (uint256);

    function lockedPeriodAmount() external view returns (uint256);

    function totalLockedRewards() external view returns (uint256);

    function getVestingAmount() external view returns (uint256, uint256);

    function farms(address) external view returns (bool);

    function devAddress() external view returns (address);
}