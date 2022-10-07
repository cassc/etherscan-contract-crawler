// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma abicoder v2;

/*
   __  ____           ____               
  /  |/  (_)__  ___  / __/    _____ ____ 
 / /|_/ / / _ \/ _ \_\ \| |/|/ / _ `/ _ \
/_/  /_/_/_//_/\___/___/|__,__/\_,_/ .__/
                                  /_/           
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
import "./IVestingMaster.sol";

interface IMinoFarm {

  /* ========== STRUCTS ========== */

    struct UserInfo {
        uint256 shares;
        uint256 rewardDebt;
        uint256 lastDepositedTime;
    }

    struct PoolInfo {
        IERC20 want;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accTokenPerShare;
        address strat;
    }

    /* ========== EVENTS ========== */

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event UpdateEmissionRate(address indexed user, uint256 tokenPerBlock);
    event UpdateEndBlock(address indexed user, uint256 endBlock);
    event SetEarlyExitFee(address indexed user, uint256 earlyExitFee);
    event SetDevAddress(address indexed user, address devAddress);
    event SetVestingMaster(address indexed user, address vestingMaster);
    event SetDevSupply(address indexed user, uint256 devSupply);

    /* ========== VIEWS ========== */

    function mino() external view returns (IERC20);

    function startBlock() external view returns (uint256);

    function poolInfo(uint256 _pid) external view returns (
        IERC20 want,
        uint256 allocPoint,
        uint256 lastRewardBlock,
        uint256 accTokenPerShare,
        address strat
    );

    function userInfo(uint256 _pid, address _account) external view returns (
        uint256 shares,
        uint256 rewardDebt,
        uint256 lastDepositedTime
    );

    function minoPerBlock() external view returns (uint256);

    function endBlock() external view returns (uint256);

    function earlyExitFee() external view returns (uint256);

    function earlyExitPeriod() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function vestingMaster() external view returns (IVestingMaster);

    function poolLength() external view returns (uint256);
    
    function stakingSupply() external view returns (uint256);

    function ifcSupply() external view returns (uint256);

    function ifcPool() external view returns (address);

    function lastBlockIfcWithdraw() external view returns (uint256);

    function setVestingMaster(address) external;

    function pendingMino(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function sharesTotal(uint256 _pid) external view returns (uint256);

    function stakedWantTokens(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, uint256 _wantAmt) external;

    function withdraw(uint256 _pid, uint256 _wantAmt) external;

    function withdrawAll(uint256 _pid) external;

    function emergencyWithdraw(uint256 _pid) external;

    /* ========== RESTRICTED FUNCTIONS ========== */

    function add(
        uint256 _allocPoint,
        IERC20 _want,
        bool _withUpdate,
        address _strat
    ) external;

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function updateMinoPerBlock(uint256 _minoPerBlock) external;

    function updateEndBlock(uint256 _endBlock) external;

    function setEarlyExitFee(uint256 _earlyExitFee) external;

    function setDevAddress(address _devAddress) external;

    function setDevSupply(uint256 _devSupply) external;

    function ifcWithdraw() external;
    
}